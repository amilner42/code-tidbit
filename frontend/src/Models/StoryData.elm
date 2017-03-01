module Models.StoryData exposing (..)

import DefaultServices.Util as Util
import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Models.Story as Story


{-| The data for the create-story page.
-}
type alias StoryData =
    { currentStory : Maybe Story.Story
    }


{-| The default empty story data.
-}
defaultStoryData : StoryData
defaultStoryData =
    { currentStory = Nothing
    }


{-| StoryData encoder.
-}
encoder : StoryData -> Encode.Value
encoder storyData =
    Encode.object
        [ ( "currentStory", Util.justValueOrNull Story.storyEncoder storyData.currentStory ) ]


{-| StoryData decoder.
-}
decoder : Decode.Decoder StoryData
decoder =
    decode StoryData
        |> required "currentStory" (Decode.maybe Story.storyDecoder)


{-| Sets the `currentStory` to `story`.
-}
setCurrentStory : Story.Story -> StoryData -> StoryData
setCurrentStory story storyData =
    { storyData
        | currentStory = Just story
    }
