# Flutter/Flame Game Scaffolding Checklist

## Purpose

This master checklist guides you through scaffolding a complete Flutter/Flame game from scratch. Follow this order to build a solid foundation before implementing core gameplay.

**Estimated Time**: 8-16 hours (depending on experience)

---

## Phase 1: Project Setup (30-60 min)

### 1.1 Create Project
- [ ] Create new Flutter project: `flutter create my_game`
- [ ] Test project runs: `flutter run`
- [ ] Set up version control: `git init`

### 1.2 Dependencies
- [ ] Add dependencies to `pubspec.yaml`:
  ```yaml
  dependencies:
    flame: ^1.33.0
    flame_audio: ^2.11.11
    shared_preferences: ^2.5.3
  ```
- [ ] Run `flutter pub get`
- [ ] Verify no dependency conflicts

### 1.3 Project Structure
- [ ] Create directory structure:
  ```
  lib/
  ├── game/
  │   ├── components/
  │   ├── systems/
  │   └── config/
  ├── screens/
  ├── widgets/
  ├── services/
  │   └── storage/
  ├── models/
  ├── theme/
  └── utils/
  ```

### 1.4 Assets Setup
- [ ] Create asset directories:
  ```
  assets/
  ├── images/
  │   ├── player/
  │   ├── obstacles/
  │   ├── collectibles/
  │   ├── backgrounds/
  │   └── ui/
  ├── audio/
  │   ├── music/
  │   └── sfx/
  └── fonts/
  ```
- [ ] Add assets to `pubspec.yaml`
- [ ] Add placeholder assets (can be simple colored squares initially)

---

## Phase 2: Theme & Styling (1-2 hours)

### 2.1 Color Palette
- [ ] Create `lib/theme/app_colors.dart`
- [ ] Define 8-12 core colors
- [ ] Define text colors with opacity variants
- [ ] Define UI element colors
- [ ] Define game-specific colors

### 2.2 Theme Configuration
- [ ] Create `lib/theme/app_theme.dart`
- [ ] Configure Material theme with `useMaterial3: true`
- [ ] Define ColorScheme
- [ ] Build complete TextTheme
- [ ] Configure component themes (AppBar, Card, Button)
- [ ] Add helper methods (text glow, stroke)

### 2.3 Custom Font
- [ ] Add font files to `assets/fonts/`
- [ ] Register fonts in `pubspec.yaml`
- [ ] Set default `fontFamily` in theme
- [ ] Test font loads correctly

**Checkpoint**: Run app with theme applied, verify colors and typography.

---

## Phase 3: Shared UI Components (2-3 hours)

### 3.1 GameLabel
- [ ] Create `lib/widgets/game_label.dart`
- [ ] Define GameLabelSize enum
- [ ] Implement size-to-property mapping
- [ ] Add text shadow/outline rendering
- [ ] Test with different sizes and colors

### 3.2 GameButton
- [ ] Create `lib/widgets/game_button.dart`
- [ ] Add AnimationController for tap animation
- [ ] Implement scale animation (0.95)
- [ ] Support icon + label layouts
- [ ] Add circular/rectangular variants
- [ ] Test responsiveness and animation

### 3.3 GameIconButton
- [ ] Create `lib/widgets/game_icon_button.dart`
- [ ] Implement circular icon button
- [ ] Add consistent sizing
- [ ] Test with different icons

### 3.4 GameDialog
- [ ] Create `lib/widgets/game_dialog.dart`
- [ ] Implement bounce-in animation (ElasticOut)
- [ ] Add fade-in overlay
- [ ] Create static `.show()` method
- [ ] Support optional title with separator
- [ ] Test dismissibility options

### 3.5 Supporting Widgets
- [ ] Create `lib/widgets/screen_header.dart` (back button + title)
- [ ] Create `lib/widgets/game_background.dart` (image/color background)
- [ ] Create `lib/widgets/hud_stat_indicator.dart` (game HUD)
- [ ] Test all components in a demo screen

**Checkpoint**: Create a demo screen showing all components working together.

---

## Phase 4: Service Architecture (2-3 hours)

### 4.1 Persistence Services
- [ ] Initialize SharedPreferences in `main.dart`
- [ ] Create `lib/services/storage/settings_service.dart`
  - [ ] Add music/sound enabled getters/setters
  - [ ] Add background setting
  - [ ] Implement factory singleton pattern
- [ ] Create `lib/services/storage/save_game_service.dart`
  - [ ] Add best score/level tracking
  - [ ] Add currency system (crystals)
  - [ ] Add purchase system
  - [ ] Add achievement unlock storage
  - [ ] Add cumulative stats (JSON)
- [ ] Test data persists across app restarts

### 4.2 Audio Service
- [ ] Create `lib/services/audio_service.dart`
- [ ] Add background music management
- [ ] Add SFX multichannel support
- [ ] Integrate with SettingsService
- [ ] Implement app lifecycle handling (pause/resume)
- [ ] Preload audio files in `initialize()`
- [ ] Test music and SFX play correctly
- [ ] Test pause on app background

### 4.3 Achievement Service
- [ ] Create `lib/models/achievement.dart`
  - [ ] Define AchievementType enum
  - [ ] Create Achievement class
- [ ] Create `lib/services/achievement_service.dart`
  - [ ] Define 10-20 achievements
  - [ ] Implement stat tracking (game + cumulative)
  - [ ] Implement unlock detection
  - [ ] Add StreamController for unlock events
  - [ ] Implement progress calculation
- [ ] Test achievements unlock correctly

### 4.4 Service Locator
- [ ] Create `lib/services/service_locator.dart`
- [ ] Add static fields for global services
- [ ] Implement getters with null checks
- [ ] Create `initialize()` method
- [ ] Add `reset()` for testing
- [ ] Initialize in `main.dart` before `runApp()`

**Checkpoint**: All services initialize without errors, basic functionality works.

---

## Phase 5: Navigation System (1-2 hours)

### 5.1 Page Routes
- [ ] Create `lib/utils/fade_page_route.dart`
- [ ] Implement FadeTransition (300ms)
- [ ] Optional: Create `lib/utils/directional_page_route.dart`
- [ ] Test transitions are smooth

### 5.2 Background Manager
- [ ] Create `lib/services/background_manager.dart`
- [ ] Add 2-4 background images to assets
- [ ] Implement random background selection
- [ ] Optional: Save selection to SettingsService

### 5.3 Three-Layer Stack
- [ ] Update `main.dart` MaterialApp.builder
- [ ] Layer 1: Background image with ValueNotifier
- [ ] Layer 2: Decorative animations (IgnorePointer + blur)
- [ ] Layer 3: Navigator (child)
- [ ] Test background persists across navigation

### 5.4 Menu Screen
- [ ] Create `lib/screens/menu_screen.dart`
- [ ] Add title/logo
- [ ] Add navigation buttons (Play, Settings, Achievements, etc.)
- [ ] Apply animations (pulse, shimmer)
- [ ] Test navigation to other screens

**Checkpoint**: Navigate between menu and placeholder screens, background persists.

---

## Phase 6: Settings & Support Screens (1-2 hours)

### 6.1 Settings Screen
- [ ] Create `lib/screens/settings_screen.dart`
- [ ] Add ScreenHeader with back button
- [ ] Add music toggle (SwitchListTile)
- [ ] Add sound toggle (SwitchListTile)
- [ ] Wire toggles to SettingsService and AudioService
- [ ] Add reset data button
- [ ] Test settings persist

### 6.2 Reset Data Dialog
- [ ] Create `lib/widgets/reset_data_dialog.dart`
- [ ] Extend GameDialog
- [ ] Add warning message
- [ ] Add cancel/confirm buttons
- [ ] Call SaveGameService.resetAllData() on confirm
- [ ] Test data resets correctly

### 6.3 Achievements Screen
- [ ] Create `lib/screens/achievements_screen.dart`
- [ ] Add ScreenHeader
- [ ] Create `lib/widgets/achievement_card.dart`
  - [ ] Show achievement icon, name, description
  - [ ] Show progress bar for locked achievements
  - [ ] Show "Unlocked!" for completed achievements
- [ ] Display list of all achievements
- [ ] Optional: Add filter by type
- [ ] Show completion percentage
- [ ] Test with locked and unlocked achievements

### 6.4 Statistics Screen (Optional)
- [ ] Create `lib/screens/statistics_screen.dart`
- [ ] Display best score, best level
- [ ] Display cumulative stats (total games, etc.)
- [ ] Display achievement completion rate

**Checkpoint**: All support screens functional, settings work, achievements display.

---

## Phase 7: Notification System (30-60 min)

### 7.1 Basic Notifications
- [ ] Create notification helper functions
- [ ] Implement SnackBar notifications (success, error, info)
- [ ] Define NotificationType enum
- [ ] Add icon and color mapping
- [ ] Test different notification types

### 7.2 Achievement Notifications
- [ ] Create special achievement unlock notification
- [ ] Add trophy icon and custom styling
- [ ] Play achievement sound
- [ ] Subscribe to AchievementService.onAchievementUnlocked
- [ ] Test notifications show on unlock

### 7.3 In-Game Toast (Optional)
- [ ] Create custom overlay toast
- [ ] Implement slide-in animation
- [ ] Support use without Scaffold
- [ ] Test in-game notifications

**Checkpoint**: Notifications work for achievements, purchases, and errors.

---

## Phase 8: Flame Integration - Basic Setup (2-3 hours)

### 8.1 Game Class
- [ ] Create `lib/game/[your_game]_game.dart`
- [ ] Extend FlameGame
- [ ] Add HasCollisionDetection mixin
- [ ] Add TapDetector or PanDetector
- [ ] Implement `onLoad()` for initialization
- [ ] Implement `update(dt)` for game loop
- [ ] Set `backgroundColor()` to transparent (see Nuances)
- [ ] Test game renders with blank screen

### 8.2 GameLoopManager
- [ ] Create `lib/game/systems/game_loop_manager.dart`
- [ ] Define GameState enum (ready, playing, paused, gameOver)
- [ ] Add score, level, lives tracking
- [ ] Implement difficulty scaling (speed, frequency multipliers)
- [ ] Add callbacks (onScoreChanged, onLevelChanged, etc.)
- [ ] Implement update(dt) for score/level progression
- [ ] Add pause/resume/reset methods
- [ ] Test state transitions

### 8.3 Game Config
- [ ] Create `lib/game/config/game_config.dart`
- [ ] Define game constants (speeds, spawn rates, etc.)
- [ ] Make values easily tunable
- [ ] Document what each value controls

### 8.4 Game Screen
- [ ] Create `lib/screens/game_screen.dart`
- [ ] Create StatefulWidget
- [ ] Create game instance in initState
- [ ] Wire up GameLoopManager callbacks
- [ ] Build Stack with GameWidget + HUD
- [ ] Add HUD with score, level, lives
- [ ] Add pause button
- [ ] Test game initializes and HUD updates

**Checkpoint**: Game screen shows, HUD updates, pause works.

---

## Phase 9: Flame Integration - Game Components (3-4 hours)

### 9.1 Player Component
- [ ] Create `lib/game/components/player_component.dart`
- [ ] Extend PositionComponent
- [ ] Add HasGameRef and CollisionCallbacks mixins
- [ ] Set size, position, anchor in onLoad
- [ ] Load player sprite
- [ ] Add CircleHitbox (smaller than sprite)
- [ ] Implement movement (tap/drag)
- [ ] Keep player on screen (constrain position)
- [ ] Optional: Add particle trail
- [ ] Optional: Add immortality mechanic
- [ ] Test player renders and moves

### 9.2 Obstacle Components
- [ ] Create `lib/game/components/[obstacle]_component.dart`
- [ ] Implement 2-3 different obstacle types
- [ ] Each has different movement pattern
- [ ] Load obstacle sprites
- [ ] Add collision hitboxes
- [ ] Implement `update()` for movement
- [ ] Remove when off-screen
- [ ] Test obstacles spawn and move

### 9.3 Collectible Components
- [ ] Create `lib/game/components/crystal_component.dart`
- [ ] Load collectible sprite
- [ ] Add rotation animation
- [ ] Add collision detection
- [ ] Call GameLoopManager on collection
- [ ] Play collection sound
- [ ] Remove on collection
- [ ] Optional: Create life collectible
- [ ] Test collectibles work

### 9.4 Background Elements (Optional)
- [ ] Create `lib/game/components/star_component.dart`
- [ ] Add slow-moving background particles
- [ ] Lower priority so they render behind gameplay
- [ ] Test parallax effect

**Checkpoint**: Full gameplay loop works - player avoids obstacles, collects items.

---

## Phase 10: Game Logic & Polish (2-3 hours)

### 10.1 Spawn System
- [ ] Add Flame Timers for spawning
- [ ] Adjust spawn rate based on difficulty
- [ ] Randomize obstacle types
- [ ] Prevent collectible overlap
- [ ] Test spawning feels balanced

### 10.2 Collision Handling
- [ ] Player takes damage on obstacle hit
- [ ] Lives decrease
- [ ] Optional: Implement immortality period
- [ ] Optional: Add blinking effect
- [ ] Game over when lives < 0
- [ ] Test collision feedback

### 10.3 Game Over Flow
- [ ] Create `lib/widgets/game_over_dialog.dart`
- [ ] Show final score and level
- [ ] Check and update best score
- [ ] Show "New Best!" badge if applicable
- [ ] Add replay button
- [ ] Add quit to menu button
- [ ] Save cumulative stats
- [ ] Trigger achievement checks
- [ ] Test game over flow

### 10.4 Pause Dialog
- [ ] Create `lib/widgets/pause_dialog.dart`
- [ ] Show resume and quit buttons
- [ ] Pause game engine
- [ ] Test pause/resume

### 10.5 Tutorial (Optional)
- [ ] Create `lib/widgets/tutorial_dialog.dart`
- [ ] Show on first launch only
- [ ] Explain controls and objectives
- [ ] Save "tutorial_shown" flag
- [ ] Test tutorial shows once

**Checkpoint**: Complete game cycle works - start, play, game over, replay.

---

## Phase 11: Audio & Achievements Integration (1-2 hours)

### 11.1 Game Audio
- [ ] Play background music on menu/game screens
- [ ] Play button sound on all button presses
- [ ] Play collection sound for crystals/lives
- [ ] Play damage sound on collision
- [ ] Play game over sound
- [ ] Optional: Play level up sound
- [ ] Test audio respects settings
- [ ] Test audio stops when app backgrounds

### 11.2 Achievement Integration
- [ ] Call AchievementService methods from game events:
  - [ ] onGameStarted() when game begins
  - [ ] onScoreChanged() on score updates
  - [ ] onLevelChanged() on level ups
  - [ ] onCrystalCollected() when collecting
  - [ ] onPlayerDeath() on death
  - [ ] onGameEnded() when game ends
- [ ] Test achievements unlock at correct times
- [ ] Test achievement notifications appear
- [ ] Test progress shows in achievement screen

**Checkpoint**: Audio and achievements fully integrated and working.

---

## Phase 12: Final Polish & Testing (2-3 hours)

### 12.1 Visual Polish
- [ ] Ensure all UI elements use theme colors
- [ ] Add animations to menu buttons
- [ ] Polish dialog animations
- [ ] Add visual feedback to all interactions
- [ ] Test on different screen sizes
- [ ] Adjust spacing and sizing for mobile

### 12.2 Difficulty Balancing
- [ ] Play test multiple sessions
- [ ] Adjust spawn rates
- [ ] Adjust obstacle speeds
- [ ] Adjust level progression speed
- [ ] Tweak difficulty scaling multipliers
- [ ] Ensure game is challenging but fair

### 12.3 Bug Fixes
- [ ] Test all navigation paths
- [ ] Test all dialogs open/close correctly
- [ ] Test settings persist
- [ ] Test achievements unlock
- [ ] Test audio plays correctly
- [ ] Fix any crashes or errors
- [ ] Handle edge cases (no audio files, missing assets, etc.)

### 12.4 Performance
- [ ] Profile with Flutter DevTools
- [ ] Ensure 60 FPS during gameplay
- [ ] Optimize asset sizes
- [ ] Limit max concurrent components
- [ ] Test on lower-end devices

### 12.5 Final Testing Checklist
- [ ] Menu navigation works
- [ ] Settings save and apply
- [ ] Game starts and plays smoothly
- [ ] Collisions feel fair
- [ ] Achievements unlock correctly
- [ ] Audio plays appropriately
- [ ] Game over flow works
- [ ] Replay works
- [ ] Background persists across screens
- [ ] No crashes during normal use
- [ ] App handles backgrounding correctly

**Checkpoint**: Game is polished and playable, no critical bugs.

---

## Phase 13: Optional Enhancements

### Shop System
- [ ] Create `lib/screens/shop_screen.dart`
- [ ] Add skin/power-up items
- [ ] Implement purchase flow
- [ ] Show currency balance
- [ ] Test purchases work

### Leaderboards (if online)
- [ ] Integrate with backend/Firebase
- [ ] Upload high scores
- [ ] Display leaderboard screen

### More Achievements
- [ ] Add hidden/secret achievements
- [ ] Add achievement rewards (currency)
- [ ] Add achievement tiers

### Advanced Effects
- [ ] Add screen shake on collision
- [ ] Add explosion particles
- [ ] Add power-up effects
- [ ] Add combo system

---

## Completion Criteria

Your game is ready when:

1. ✅ All core systems implemented
2. ✅ Full game loop functional (start → play → game over → replay)
3. ✅ Settings persist and apply correctly
4. ✅ Achievements unlock and save
5. ✅ Audio plays and respects settings
6. ✅ No critical bugs or crashes
7. ✅ Performance is smooth (60 FPS)
8. ✅ Game is fun to play!

---

## What's Next?

Now that you have a complete scaffold:

1. **Add unique gameplay mechanics** - This is what makes your game different!
2. **Create more content** - More levels, obstacles, achievements
3. **Polish visuals** - Better graphics, animations, effects
4. **Add monetization** - Ads, IAP, etc. (if desired)
5. **Playtest extensively** - Get feedback and iterate
6. **Publish** - Release to App Store and Play Store

---

## Quick Reference: Implementation Order

1. Project setup → Theme → UI components
2. Services (persistence, audio, achievements)
3. Navigation and menu
4. Settings and support screens
5. Flame game basics (game class, game loop)
6. Game components (player, obstacles, collectibles)
7. Game logic and polish
8. Integration (audio, achievements)
9. Testing and balancing
10. Optional enhancements

**Total estimated time**: 15-25 hours for complete scaffold (before unique gameplay).

Good luck with your game! 🎮
