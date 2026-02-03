# Stone Pine Survival

Made for the [Games for Blind Gamers 5](https://itch.io/jam/games-for-blind-gamers-5).

## Instructions

### Clone the repo

```bash
git clone https://github.com/orcakt/gamejam-feb-2026.git
```

### Checkout a Branch

```bash
git checkout -b [feature/* || fix/*]
```

### Add and Commit Changes

Some kind of GUI is good for this, like [GitHub Desktop](https://github.com/apps/desktop).

```bash
git add . && git commit -m "*commit message*"
```

### Push Branch to Origin

```bash
git push origin *branch_name*
```

### Create a PR

Follow these [instructions](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request).

### Merge PR

Merge the PR into the `main` branch.

### Pull Latest Update

Make sure you pull the changes to `main` origin into your local `main`.

```bash
git checkout main && git pull origin main
```

## File Organization

Files are organized by their relative game application (where they are used - roughly).

- assets: imported data
  - music
  - sfx
  - textures
- systems: more data focused classes and nodes
  - crafting: mutating items
  - inventory: organizing the players things
  - multiplayer: managers of multiplayer
  - sound: balences music and sfx
  - stats: health, hunger, thirst
- tests: scenes for user testing
- ui: user interface
  - game: ui during gameplay
  - main: main menu ui
- world: interactable scenes, usually 2D
  - camp: the main base
  - character: the player character
  - items: interactable resources
  - terrain: parts of the world that are non interactable
  - vines: the environmental hazard
