module Models.Completed exposing (..)

import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Models.TidbitPointer as TidbitPointer


{-| Marks a completed tidbit for a user. This matches the format on the backend.
-}
type alias Completed =
    { tidbitPointer : TidbitPointer.TidbitPointer
    , user : String
    }


{-| Convenience for storing on the frontend and keeping track of if something
is completed. This is not replicated on the backend.
-}
type alias IsCompleted =
    { tidbitPointer : TidbitPointer.TidbitPointer
    , complete : Bool
    }


{-| Makes a `Completed` from an `IsCompleted` and a userID.
-}
completedFromIsCompleted : IsCompleted -> String -> Completed
completedFromIsCompleted isCompleted userID =
    Completed isCompleted.tidbitPointer userID


{-| Completed encoder.
-}
encoder : Completed -> Encode.Value
encoder completed =
    Encode.object
        [ ( "tidbitPointer", TidbitPointer.encoder completed.tidbitPointer )
        , ( "user", Encode.string completed.user )
        ]


{-| Completed decoder.
-}
decoder : Decode.Decoder Completed
decoder =
    decode Completed
        |> required "tidbitPointer" TidbitPointer.decoder
        |> required "user" Decode.string


{-| IsCompleted encoder.
-}
isCompletedEncoder : IsCompleted -> Encode.Value
isCompletedEncoder isCompleted =
    Encode.object
        [ ( "tidbitPointer", TidbitPointer.encoder isCompleted.tidbitPointer )
        , ( "complete", Encode.bool isCompleted.complete )
        ]


{-| IsCompleted decoder.
-}
isCompletedDecoder : Decode.Decoder IsCompleted
isCompletedDecoder =
    decode IsCompleted
        |> required "tidbitPointer" TidbitPointer.decoder
        |> required "complete" Decode.bool


{-| Given a tidbit pointer, returns
-}
isCompletedFromBoolDecoder : TidbitPointer.TidbitPointer -> Decode.Decoder IsCompleted
isCompletedFromBoolDecoder tidbitPointer =
    Decode.bool
        |> Decode.map (IsCompleted tidbitPointer)
