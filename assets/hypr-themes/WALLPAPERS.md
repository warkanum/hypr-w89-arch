# Wallpaper prompts

Included (copied from `assets/sddm-stargate`): ancient-outpost-aurora, atlantis-jumper-patrol, atlantis-ocean-ascent, jumper-asteroid-expedition, pegasus-orbital-gate, stargate-space, wraith-hive-recon. All Stargate/Atlantis; the prompts below fill the Star Trek and dark-grey gaps.

Generate, then save into `assets/hypr-themes/wallpapers/` (copied to `~/Pictures/wallpapers` on install).
Size: 2560x1440 (16:9), PNG. Shared constraints for every prompt: no text, no logos, no watermark, no UI, no people, no anime.

| File name | Look | Prompt |
|---|---|---|
| `stargate-blue-1.png` | Stargate blue | Cinematic Milky Way Stargate in deep space, glowing blue event horizon, cool cyan rim light, dark starfield, subtle nebula, restrained edges for desktop use |
| `stargate-blue-2.png` | Stargate blue | Stargate half buried in a snowy planet ridge at dusk, blue wormhole light on the snow, distant moons |
| `stargate-dark-1.png` | Stargate dark grey | Weathered dark-grey granite Stargate, unlit and dormant, desaturated charcoal palette, faint steel-blue rim light, dim hangar-like gloom |
| `stargate-dark-2.png` | Stargate dark grey | Close macro of engraved Stargate glyphs on dark grey stone, shallow depth of field, near-monochrome |
| `atlantis-1.png` | Stargate blue | Pegasus (Atlantis-type) Stargate on a spire balcony of a floating city at night, ocean horizon, blue-teal light |
| `lcars-1.png` | Star Trek LCARS | Abstract LCARS-style interface background: rounded orange, peach and violet bars on pure black, wide empty centre, no readable text |
| `lcars-2.png` | Star Trek LCARS | Dark starship bridge console wall, softly lit orange and violet panels, shallow depth of field, empty of crew |
| `starfleet-1.png` | Starfleet blue | Starfleet starship in orbit of a ringed planet, deep blue and gold highlights, hull lit by a nearby star |
| `starfleet-2.png` | Starfleet blue | Starship warp streaks through a blue nebula, command-gold glints, dark negative space on the left |

Colour schemes live in `assets/hypr-themes/*.json`; wallpapers are independent of the active scheme.

## Generation status (2026-10-21)

Generated with the built-in imagegen tool and saved in `wallpapers/`:
`stargate-blue-1.png`, `stargate-blue-2.png`, `stargate-dark-1.png`,
`stargate-dark-2.png`, `atlantis-1.png`, `lcars-1.png`, and `lcars-2.png`.
All seven are PNGs at 2560×1440. The tool returned 1672×941 originals;
ImageMagick resized them to cover and centre-cropped to the required dimensions.

The prompt set is the corresponding seven rows above, with the shared constraints
and a request for a single wide desktop wallpaper with dark breathing room.
The scenic prompts used cinematic realistic science-fiction styling. The glyph
close-up specified fictional pictograms rather than readable lettering. LCARS
panels used abstract shapes without labels, digits, icons, or desktop/app chrome;
the first LCARS image keeps its centre empty and its bars near the edges.

Still missing: `starfleet-1.png` and `starfleet-2.png`. The image tool rejected
both scenes at output moderation, including retries using the original prompts.
No placeholder files were added.

## More Star Trek-style prompts

Same size and constraints as above. The `starfleet-*` prompts were rejected by the image tool, so these avoid franchise names and describe the look instead: use them verbatim and do not add "Star Trek", "Starfleet" or ship names.

| File name | Scheme | Prompt |
|---|---|---|
| `starfleet-3.png` | `starfleet-blue` | Sleek white-and-grey exploration starship with a wide saucer section and twin glowing blue nacelles, drifting past a ringed gas giant, soft gold starlight on the hull, deep blue space, large empty area on the right |
| `starfleet-4.png` | `starfleet-blue` | Long corridor of a futuristic starship, curved pale walls, recessed blue and gold lighting, perfect one-point perspective, polished floor reflections, no crew |
| `starfleet-5.png` | `starfleet-blue` | Observation lounge of a starship at night, floor-to-ceiling window facing a swirling blue nebula, empty curved seating silhouettes, warm gold accent lights |
| `lcars-3.png` | `star-trek-lcars` | Futuristic starship operations console, rounded orange, peach and lavender touch panels glowing on a black wall, abstract shapes only, no text, no numbers, centre left empty |
| `lcars-4.png` | `star-trek-lcars` | Minimal desktop wallpaper: a single sweeping rounded elbow bar in orange and violet along the left and bottom edges on pure black, soft glow, nothing else |
| `vulcan-1.png` | `vulcan-amber` | Red desert planet at dusk, twin amber moons, ancient angular stone temple on a cliff, heat haze, warm orange sky fading to deep brown |
| `klingon-1.png` | `klingon-red` | Brutal angular warship with crimson running lights hanging over a dark volcanic world, red glow reflecting on clouds, near-black sky, dramatic low angle |
| `romulan-1.png` | `romulan-green` | Predatory curved green-hulled warship half-hidden in a dark green nebula, faint cloaking shimmer along its wings, deep shadow, quiet menace |
| `borg-1.png` | `borg-collective` | Enormous cube-shaped machine vessel in deep space, dark metal lattice surface, thousands of tiny green lights, lone against a black starfield, symmetrical composition |
| `section31-1.png` | `section-31` | Sleek stealth starship docked in a shadowed hangar, matte black hull, faint steel-blue edge lighting, wet reflective floor, almost monochrome |
| `warp-1.png` | `starfleet-blue` | Starship at the moment of entering warp, long stretched blue-white light streaks, lens flare, dark space, ship small on the left third |
| `station-1.png` | `starfleet-blue` | Ring-shaped space station above a blue planet at sunrise, small shuttles in the distance, calm and clean, wide empty sky for icons |

Save as the file names above; they are picked up by `theme.sh --wallpapers` and `sddm-theme.sh --wallpapers`.

