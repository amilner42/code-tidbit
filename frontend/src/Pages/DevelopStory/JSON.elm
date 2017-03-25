module Pages.DevelopStory.JSON exposing (..)

import DefaultServices.Util as Util
import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import JSON.Story
import JSON.Tidbit
import Pages.DevelopStory.Model exposing (..)


{-| `DevelopStoryModel` encoder.
-}
encoder : Model -> Encode.Value
encoder storyData =
    Encode.object
        [ ( "currentStory"
          , Util.justValueOrNull
                JSON.Story.expandedStoryEncoder
                storyData.currentStory
          )
        , ( "tidbitsToAdd"
          , Encode.list <| List.map JSON.Tidbit.encoder storyData.tidbitsToAdd
          )
        ]


{-| `DevelopStoryModel` decoder.
-}
decoder : Decode.Decoder Model
decoder =
    decode Model
        |> required "currentStory"
            (Decode.maybe JSON.Story.expandedStoryDecoder)
        |> required "tidbitsToAdd"
            (Decode.list JSON.Tidbit.decoder)
