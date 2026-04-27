# Threads Feed

Experimental iOS project — reimplementing a Threads-like feed with media preview, full-screen viewing, and animations.

## Feature details

Some of the less obvious behavior implemented so far:

- Full-screen image preview with a custom zoom transition from the tapped feed image.
- Swipe-to-dismiss from full-screen preview.
- Pinch-to-zoom and double-tap-to-zoom in full-screen preview.
- Swipe-to-dismiss is disabled while the image is zoomed, so pan gestures can be used for zoomed image navigation.
- The feed stays visible and scrollable behind the preview while the dismiss animation runs.
- The currently opened image is blacked out in the underlying feed carousel, so the animated image does not visually duplicate it.
- When paging between images in full-screen preview, the underlying feed carousel scrolls to the same selected image and moves the blackout state with it.
- Horizontal dismiss gestures match paging edges:
  - With a single image, swipe-to-dismiss can start in any direction.
  - With multiple images, swiping right on the first image can dismiss because there is no previous page.
  - On the last image, swiping left is left to the paging scroll view, so it bounces instead of dismissing, similar to Threads.
- Rounded corners are animated during transitions between feed cells and full-screen preview.
- The close button uses the same return-to-source animation as swipe-to-dismiss.
- If the original feed cell is no longer available, dismissal falls back to a fly-off/fade animation instead of breaking.
- Full-screen images are aspect-fit; feed thumbnails are aspect-fill.
- Feed attachment sizing:
  - A single image expands to the available content width and uses its real aspect ratio for height, clamped between `200` and `450` points.
  - Multiple attachments use equal-size carousel tiles (`280×350` points), even when the images have different resolutions or aspect ratios.
  - The app currently loads the URL attached to each `ImageAttachment`; there is no separate thumbnail/full-size URL selection yet.
- Async image loading is handled with Nuke/NukeUI, with placeholders and request cancellation on cell reuse.
- Posts support text-only, image-only, and text-with-images layouts, including dynamic cell heights and relative timestamps.

## Roadmap

See [TODO.md](TODO.md).
