module Pages.NewStory.JSON exposing (..)

import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import JSON.Story
import Pages.NewStory.Model exposing (..)
import Models.Story as Story


{-| `NewStoryModel` encoder.
-}
encoder : Model -> Encode.Value
encoder model =
    Encode.object
        [ ( "newStory", JSON.Story.newStoryEncoder model.newStory )
        , ( "editingStory", JSON.Story.encoder model.editingStory )
        , ( "tagInput", Encode.string model.tagInput )
        , ( "editingStoryTagInput", Encode.string model.editingStoryTagInput )
        ]


{-| `NewStoryModel` decoder.
-}
decoder : Decode.Decoder Model
decoder =
    decode Model
        |> required "newStory" JSON.Story.newStoryDecoder
        |> required "editingStory" JSON.Story.decoder
        |> required "tagInput" Decode.string
        |> required "editingStoryTagInput" Decode.string
