module JSON.TutorialBookmark exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Json.Encode as Encode
import Models.TutorialBookmark exposing (..)


{-| `TutorialBookmark` encoder.
-}
encoder : TutorialBookmark -> Encode.Value
encoder =
    toString >> Encode.string


{-| `TutorialBookmark` decoder.
-}
decoder : Decode.Decoder TutorialBookmark
decoder =
    let
        decodeFailure encodedBookmark =
            Decode.fail <| "Tutorial bookmark encoding not valid: " ++ encodedBookmark

        frameNumberPrefixString =
            "FrameNumber "

        fromStringDecoder encodedBookmark =
            case encodedBookmark of
                "Introduction" ->
                    Decode.succeed Introduction

                "Conclusion" ->
                    Decode.succeed Conclusion

                _ ->
                    if String.startsWith frameNumberPrefixString encodedBookmark then
                        encodedBookmark
                            |> String.dropLeft (String.length frameNumberPrefixString)
                            |> String.toInt
                            |> (\result ->
                                    case result of
                                        Err _ ->
                                            decodeFailure encodedBookmark

                                        Ok int ->
                                            Decode.succeed <| FrameNumber int
                               )
                    else
                        decodeFailure encodedBookmark
    in
        Decode.string |> Decode.andThen fromStringDecoder
