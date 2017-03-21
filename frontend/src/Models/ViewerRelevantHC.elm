module Models.ViewerRelevantHC exposing (..)

import Array
import DefaultServices.Util as Util


{-| The relevant highlighted comments for a selected range as well as the
as a field (`currentHC`) for keeping track of the current HC that the user is
reading.
-}
type alias ViewerRelevantHC hcType =
    { currentHC : Maybe Int
    , relevantHC : Array.Array ( Int, hcType )
    }


{-| Returns true if there are no relevant HC.
-}
isEmpty : ViewerRelevantHC a -> Bool
isEmpty =
    .relevantHC >> Array.isEmpty


{-| Returns true if viewing the first frame.
-}
onFirstFrame : ViewerRelevantHC a -> Bool
onFirstFrame =
    .currentHC >> ((==) <| Just 0)


{-| Returns true if viewing the last frame.
-}
onLastFrame : ViewerRelevantHC a -> Bool
onLastFrame vr =
    vr.currentHC == Just ((Array.length vr.relevantHC) - 1)


{-| Returns the current frame and the total number of frames, 1-based-indexing.
-}
currentFramePair : ViewerRelevantHC a -> Maybe ( Int, Int )
currentFramePair vr =
    case vr.currentHC of
        Nothing ->
            Nothing

        Just currentPos ->
            Just ( currentPos + 1, Array.length vr.relevantHC )


{-| Returns true if the user is browsing the relevant HC.
-}
browsingFrames : ViewerRelevantHC a -> Bool
browsingFrames vr =
    Util.isNotNothing <| currentFramePair vr


{-| Returns true if the viewer has relevant HC to be browsed but the user is
currently not browsing any.
-}
hasFramesButNotBrowsing : ViewerRelevantHC a -> Bool
hasFramesButNotBrowsing vr =
    Util.isNothing vr.currentHC && (not <| isEmpty vr)


{-| Goes to the next frame if possible.
-}
goToNextFrame : ViewerRelevantHC a -> ViewerRelevantHC a
goToNextFrame vr =
    { vr
        | currentHC =
            if onLastFrame vr then
                vr.currentHC
            else
                Maybe.map ((+) 1) vr.currentHC
    }


{-| Goes the previous frame if possible.
-}
goToPreviousFrame : ViewerRelevantHC a -> ViewerRelevantHC a
goToPreviousFrame vr =
    { vr
        | currentHC =
            if onFirstFrame vr then
                vr.currentHC
            else
                Maybe.map ((flip (-)) 1) vr.currentHC
    }
