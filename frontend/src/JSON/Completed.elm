module JSON.Completed exposing (..)

import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import JSON.TidbitPointer
import Models.Completed exposing (..)


{-| `Completed` encoder.
-}
encoder : Completed -> Encode.Value
encoder completed =
    Encode.object
        [ ( "tidbitPointer", JSON.TidbitPointer.encoder completed.tidbitPointer )
        , ( "user", Encode.string completed.user )
        ]


{-| `Completed` decoder.
-}
decoder : Decode.Decoder Completed
decoder =
    decode Completed
        |> required "tidbitPointer" JSON.TidbitPointer.decoder
        |> required "user" Decode.string


{-| `IsCompleted` encoder.
-}
isCompletedEncoder : IsCompleted -> Encode.Value
isCompletedEncoder isCompleted =
    Encode.object
        [ ( "tidbitPointer", JSON.TidbitPointer.encoder isCompleted.tidbitPointer )
        , ( "complete", Encode.bool isCompleted.complete )
        ]


{-| `IsCompleted` decoder.
-}
isCompletedDecoder : Decode.Decoder IsCompleted
isCompletedDecoder =
    decode IsCompleted
        |> required "tidbitPointer" JSON.TidbitPointer.decoder
        |> required "complete" Decode.bool
