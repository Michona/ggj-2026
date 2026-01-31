# Endless Runner Game - Isometric Edition

A simple endless runner game inspired by Subway Surfers with an isometric/pseudo-3D perspective similar to Diablo-like games, built with DragonRuby Game Toolkit.

## How to Run

1. Copy the `test-first-game` folder to your DragonRuby GTK installation directory
2. Run DragonRuby and select the `test-first-game` folder
3. Or run from command line: `./dragonruby test-first-game`

## Controls

- **Arrow Keys** or **A/D Keys**: Move left/right between lanes
- **R Key**: Restart game (when game over)

## Gameplay

- Your character automatically runs forward at a constant speed
- Switch between 3 lanes to avoid obstacles and collect coins
- **Obstacles (Red Buses)**: Hitting them reduces your speed significantly
- **Coins (Gold Squares)**: Collecting them increases your score and boosts speed
- **Speed Decay**: Your speed gradually decreases over time
- **Game Over**: When your speed drops too low, the police catch you!

## Visual Features

- **Isometric Perspective**: Top-down angled view similar to Diablo, Path of Exile, and classic isometric RPGs
- **Depth Perception**: Objects appear smaller as they get further away (higher on screen)
- **Converging Lanes**: Road lanes converge toward a vanishing point to create 3D depth
- **Perspective Scaling**: All game objects scale based on their distance from the camera
- **Player**: Blue rectangle at the bottom-center, viewed from a 45-degree angle
- **Obstacles**: Red rectangles (buses) that appear in the distance and approach the player
- **Coins**: Gold squares that spawn far away and move toward the player
- **Road**: Three lanes with animated dividers that create a sense of movement and depth

## Scoring

- Distance traveled = Base score
- Each coin collected = +10 points
- Try to survive as long as possible!

## Tips

- Collect coins to maintain your speed
- Avoid obstacles to prevent speed loss
- Plan your lane switches ahead of time
- Watch the speed bar - don't let it get too low!
- Objects in the distance appear smaller - use this visual cue to plan ahead!
