# BiomeControl

> Control the structure of each biome in both routes.

Part of the [Run Director modpack](https://github.com/h2pack-rundirector/run-director-modpack).

## What It Does

BiomeControl lets you shape what happens inside each biome rather than simply accepting the default encounter mix.

The module is organized by biome and exposes controls for things like:

- forcing, disabling, or leaving specific room categories at default
- setting min/max biome-depth windows for special rooms such as trials, fountains, shops, minibosses, and named NPC encounters
- controlling when biome-specific NPC encounters can appear
- setting route reward priorities, including preferred boon rewards for each biome and for trial choices

In practice, this means you can push a biome toward a more predictable structure:

- guarantee that certain encounter types show up in a specific depth range
- block unwanted side content from entering the room pool
- make special encounters appear earlier, later, or not at all
- bias the route toward the reward types you actually want to see

Use it when you want to direct biome pacing and encounter composition without rewriting the whole run into a static script.

## Current Biome Coverage

- `Erebus`
  Controls Arachne, Trial, Fountain, Shop, and the three minibosses.
- `Oceanus`
  Controls Narcissus, Trial, Fountain, Shop, and the three minibosses.
- `Fields`
  Controls the two minibosses, plus:
  - `Prevent Echo Scam`
  - `Force 2-2 Fields`
- `Tartarus`
  Controls the two minibosses.
- `Ephyra`
  Controls Medea room, which miniboss will appear, Heracles/Artemis encounter timing, replace Hermes boon in Ephyra with another god, and bans for normal/hard subroom reward pools.
- `Thessaly`
  Controls Circe, Trial, Fountain, Shop, Heracles, Icarus, and a dedicated miniboss selector with a forced depth range.
- `Olympus`
  Controls Dionysus, Fountain, Shop, Heracles, Athena, Icarus, and the two minibosses.
- `Summit`
  No controls currently.

The module also includes a option to select what the first boon in every biome will be and what goods are favored to appear in trial rooms.

## Installation

Install via [r2modman](https://thunderstore.io/c/hades-ii/) or manually place in your `ReturnOfModding/plugins` folder.

This module is usually installed as part of the full [Run Director modpack](https://github.com/h2pack-rundirector/run-director-modpack), where it appears in the shared Run Director UI with the other run-control modules.
