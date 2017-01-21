{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE ScopedTypeVariables #-}
module Alienator.Main
  (
    main
  ) where

import Control.Monad
import Control.Monad.Trans
import Control.Lens hiding ((#))
import Reflex.Cocos2d
import Reflex.State

import Linear.Affine
import Diagrams (unr2)
import Diagrams.TwoD.Shapes

import Alienator.GamePlayScene
import Alienator.State
import Alienator.Constants


data Scene = StartScene | GamePlayScene | GameOverScene deriving (Show, Read, Eq)

main :: IO ()
main = mainScene $ do
    winSize <- view windowSize
    keysDyn <- getKeyboardEvents >>= accumKeysDown

    (sp, steps) <- space [ iterations := 2 ]
    collisionEvts <- getCollisionEvents sp
    let collisionsE = fanCollisionsByBody (collisionEvts^.collisionBegan)
    -- walls
    wb <- body sp [ position := P (winSize/2) ]
    let rectPts = uncurry rect $ unr2 (winSize + 100)
    forM_ (zip rectPts $ tail $ cycle rectPts) $ \(a, b) ->
      void $ shape sp wb (LineSegment a b 100)
        [ active   := True
        , category := Wall
        ]
    void $ runAccStateT ?? StartScene $ do
      seqDyn' <=< watches $ \case
        StartScene -> do
          (_, clicked) <- button
            [ titleText       := "Start"
            , titleFontSize   := 20
            , positionPercent := pure 0.5
            ]
          adjust $ const GamePlayScene <$ clicked
        GamePlayScene -> do
          liftIO $ putStrLn "playing game!"
          overE <- lift . flip evalAccStateT (initGamePlaySceneState winSize) $ do
            gamePlayScene winSize sp steps collisionsE keysDyn
          adjust $ const GameOverScene <$ overE
        GameOverScene -> do
          (_, clicked) <- button
            [ titleText       := "Game Over"
            , titleFontSize   := 50
            , positionPercent := pure 0.5
            ]
          adjust $ const StartScene <$ clicked