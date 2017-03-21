module JSON.StoryData exposing (..)

import DefaultServices.Util as Util
import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import JSON.Story as JSONStory
import JSON.Tidbit as JSONTidbit
import Models.StoryData exposing (..)


{-| `StoryData` encoder.
-}
encoder : StoryData -> Encode.Value
encoder storyData =
    Encode.object
        [ ( "currentStory", Util.justValueOrNull JSONStory.expandedStoryEncoder storyData.currentStory )
        , ( "tidbitsToAdd", Encode.list <| List.map JSONTidbit.encoder storyData.tidbitsToAdd )
        ]


{-| `StoryData` decoder.
-}
decoder : Decode.Decoder StoryData
decoder =
    decode StoryData
        |> required "currentStory" (Decode.maybe JSONStory.expandedStoryDecoder)
        |> required "tidbitsToAdd" (Decode.list JSONTidbit.decoder)
