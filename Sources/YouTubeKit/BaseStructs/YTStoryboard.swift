import Foundation

/// Struct representing the seek-preview images of a video.
///
/// A storyboard stores frames in sprite sheets so a player can display a preview while the user seeks without downloading one image per frame.
public struct YTStoryboard: Sendable, Hashable {
    /// Image variant available for a storyboard.
    ///
    /// Each level contains the same video timeline at a specific image size.
    /// Its frames are arranged into one or more sprite-sheet grids.
    public struct Level: Sendable, Hashable {
        /// Zero-based level index used by the storyboard URL template.
        public let index: Int

        /// Width of each frame, in pixels.
        public let width: Int

        /// Height of each frame, in pixels.
        public let height: Int

        /// Total number of frames available across all sprite sheets.
        public let frameCount: Int

        /// Number of frame columns in each sprite sheet.
        public let columns: Int

        /// Number of frame rows in each sprite sheet.
        public let rows: Int

        /// Time between consecutive frames, in milliseconds.
        /// A value of `0` means the interval must be derived from the video duration.
        public let intervalMilliseconds: Int

        /// Sprite-sheet name containing a `$M` sheet-index placeholder.
        let nameTemplate: String

        /// Signature appended to the generated sprite-sheet URL as `sigh`.
        let signature: String
    }

    /// Location of a seek-preview frame inside a sprite sheet.
    public struct Tile: Sendable, Hashable {
        /// URL of the complete sprite sheet containing the frame.
        public let url: URL

        /// Storyboard level selected for the requested size.
        public let level: Level

        /// Zero-based column of the frame in the sprite sheet.
        public let column: Int

        /// Zero-based row of the frame in the sprite sheet.
        public let row: Int
        
        #if canImport(CoreGraphics)
        func getPositionInLevel() throws -> CGRect {
            guard self.column >= 0 && self.column < self.level.columns && self.row >= 0 && self.row < self.level.rows else {
                throw "Tile is not in the bounds of the Level"
            }
            return CGRect(x: self.column * self.level.width, y: self.row * self.level.height, width: self.level.width, height: self.level.height)
        }
        #endif
    }

    /// Image variants decoded from the storyboard specification.
    public let levels: [Level]

    /// Index of YouTube's preferred level, or `nil` when none is provided.
    public let recommendedLevel: Int?

    /// Sprite-sheet URL containing the `$L` level and `$N` name placeholders.
    private let urlTemplate: String

    /// Decode a `playerStoryboardSpecRenderer` storyboard specification.
    /// - Parameters:
    ///   - spec: The URL template followed by the `|`-separated level descriptions.
    ///   - recommendedLevel: Index of YouTube's preferred level, when provided.
    /// - Returns: A storyboard, or `nil` if the specification contains no URL template or valid level.
    public init?(
        spec: String,
        recommendedLevel: Int?
    ) {
        /*
         Example values:
         - spec: https://i.ytimg.com/sb/__fmDj0ZJ1Q/storyboard3_L$L/$N.jpg?sqp=-oaymwquKqQOYAYgBAZUBAAAEQpgBMqABPDBAVHyYtDg4PEhcrLCkPDhAVHyoyKQ8RFBgmPHSWFM0BCQ0xERkO6AUARERUjRENDQxETFi9DQ0NDFRYpQ0NDQ0MjL0NDQ0NDQ0RDQ0NDQ0JCQ0NDQ0NCQkJDQ0NDQkJCQkNDQ0JCovOX_wMGCEG|48#27#100#10#10#0#default#rs$AOn4CLDYXZiVUt4yFhkYw|80#45#194#10#10#10000#M$M#rs$AOnLWBns6-WmlbXB8MODgyQ|160#90#194#5#5#10000#M$M#rs$AOn4CLT70lXkJV85Lpon0kA|320#180#194#3#3#10000#M$M#rs$AOn4CLAy2ed8quykOlPiaww
         */
        let parts = spec.split(separator: "|", omittingEmptySubsequences: false)
        guard let template = parts.first, !template.isEmpty else { return nil }

        let levels = parts.dropFirst().enumerated().compactMap { index, rawLevel -> Level? in
            let fields = rawLevel.split(
                separator: "#",
                maxSplits: 7,
                omittingEmptySubsequences: false
            )
            guard fields.count == 8,
                  let width = Int(fields[0]), width > 0,
                  let height = Int(fields[1]), height > 0,
                  let frameCount = Int(fields[2]), frameCount > 0,
                  let columns = Int(fields[3]), columns > 0,
                  let rows = Int(fields[4]), rows > 0,
                  let interval = Int(fields[5]), interval >= 0
            else { return nil }
            return Level(
                index: index,
                width: width,
                height: height,
                frameCount: frameCount,
                columns: columns,
                rows: rows,
                intervalMilliseconds: interval,
                nameTemplate: String(fields[6]),
                signature: String(fields[7])
            )
        }
        guard !levels.isEmpty else { return nil }

        urlTemplate = String(template)
        self.levels = levels
        self.recommendedLevel = recommendedLevel
    }

    /// Get the sprite-sheet location of the preview frame at a playback time.
    ///
    /// The recommended level is used when it fits. Otherwise, the largest fitting level is selected, or the largest level when none fit.
    /// - Parameters:
    ///   - time: Playback time of the requested frame, in seconds.
    ///   - duration: Duration of the video, in seconds. Used when a level does not provide a frame interval.
    ///   - maximumWidth: Maximum preferred frame width, in pixels.
    ///   - maximumHeight: Maximum preferred frame height, in pixels.
    /// - Returns: The sprite-sheet URL and crop position, or `nil` if the URL cannot be created.
    public func tile(
        at time: TimeInterval,
        duration: TimeInterval,
        maximumWidth: Int,
        maximumHeight: Int
    ) -> Tile? {
        /**
         Level selection algo:
         1. Get the levels smaller than the max height/width. If none, retain all the others
         2. In the selected levels, take the first one that is recommended in``YTStoryboard/recommendedLevel``. If none, take the level with the smallest amount of pixels
         */
        
        // 1
        let fitting = levels.filter {
            $0.width <= maximumWidth && $0.height <= maximumHeight
        }
        let candidates = fitting.isEmpty ? levels : fitting
        
        // 2
        let preferred = recommendedLevel.flatMap { preferred in
            candidates.first { $0.index == preferred }
        }
        guard let level = preferred ?? candidates.max(by: {
            $0.width * $0.height < $1.width * $1.height
        }) else { return nil }

        let interval = level.intervalMilliseconds > 0
            ? TimeInterval(level.intervalMilliseconds) / 1_000
            : max(duration / TimeInterval(level.frameCount), 0.001) /// framecount is guaranteed non-null when initiated from ``YTStoryboard/init(spec:recommendedLevel:)``
        
        let elapsedTime: TimeInterval = max(0, time)
        let calculatedFrame = Int(floor(elapsedTime / interval))
        let frame: Int = min(max(calculatedFrame, 0), level.frameCount - 1)
        
        let tilesPerSheet: Int = level.columns * level.rows
        let sheet: Int = frame / tilesPerSheet
        let tile: Int = frame % tilesPerSheet
        let name = level.nameTemplate.replacingOccurrences(of: "$M", with: String(sheet))
        var urlString = urlTemplate
            .replacingOccurrences(of: "$L", with: String(level.index))
            .replacingOccurrences(of: "$N", with: name)
        urlString += urlString.contains("?") ? "&" : "?"
        urlString += "sigh=\(level.signature)"
        guard let url = URL(string: urlString) else { return nil }
        return Tile(
            url: url,
            level: level,
            column: tile % level.columns,
            row: tile / level.columns
        )
    }
}
