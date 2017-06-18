module JSON.ViewerRelevantHC exposing (..)

import Array
import DefaultServices.Util as Util
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, hardcoded, optional, required)
import Json.Encode as Encode
import Models.ViewerRelevantHC exposing (..)


{-| `ViewerRelevantHC` encoder.
-}
encoder : (hcType -> Encode.Value) -> ViewerRelevantHC hcType -> Encode.Value
encoder encodeHC viewerRelevantHC =
    Encode.object
        [ ( "currentHC", Util.justValueOrNull Encode.int viewerRelevantHC.currentHC )
        , ( "relevantHC"
          , Encode.array <|
                Array.map
                    (\hc ->
                        Encode.object
                            [ ( "frameIndex", Encode.int <| Tuple.first hc )
                            , ( "hc", encodeHC <| Tuple.second hc )
                            ]
                    )
                    viewerRelevantHC.relevantHC
          )
        ]


{-| `ViewerRelevantHC` decoder.
-}
decoder : Decode.Decoder hcType -> Decode.Decoder (ViewerRelevantHC hcType)
decoder decodeHC =
    decode ViewerRelevantHC
        |> required "currentHC" (Decode.maybe Decode.int)
        |> required "relevantHC"
            (Decode.array
                (decode (,)
                    |> required "frameIndex" Decode.int
                    |> required "hc" decodeHC
                )
            )
