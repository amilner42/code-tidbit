module Models.ViewStoryData exposing (..)

import DefaultServices.Util as Util
import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Models.Story as Story


{-| The data for viewing a story.
-}
type alias ViewStoryData =
    { currentStory : Maybe Story.ExpandedStory
    }


{-| Blank default view story data.
-}
defaultViewStoryData : ViewStoryData
defaultViewStoryData =
    { currentStory = Nothing }


{-| Updates the current story.
-}
setCurrentStory : Maybe Story.ExpandedStory -> ViewStoryData -> ViewStoryData
setCurrentStory newExpandedStory viewStoryData =
    { viewStoryData
        | currentStory = newExpandedStory
    }


{-| ViewStoryData encoder.
-}
encoder : ViewStoryData -> Encode.Value
encoder viewStoryData =
    Encode.object
        [ ( "currentStory", Util.justValueOrNull Story.expandedStoryEncoder viewStoryData.currentStory ) ]


{-| ViewStoryData decoder.
-}
decoder : Decode.Decoder ViewStoryData
decoder =
    decode ViewStoryData
        |> required "currentStory" (Decode.maybe Story.expandedStoryDecoder)
