module Models.Bigbit exposing (..)

import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)


{-| A Bigbit as seen in the database.
-}
type alias Bigbit =
    { name : String
    , description : String
    , tags : List String
    }


{-| A full bigbit ready for publication.
-}
type alias BigbitForPublication =
    { name : String
    , description : String
    , tags : List String
    }


{-| The data being stored for a bigbit being created.
-}
type alias BigbitCreateData =
    { name : String
    , description : String
    , tags : List String
    , tagInput : String
    }


{-| BigbitCreateData `cacheEncoder`.
-}
bigbitCreateDataCacheEncoder : BigbitCreateData -> Encode.Value
bigbitCreateDataCacheEncoder bigbitCreateData =
    Encode.object
        [ ( "name", Encode.string bigbitCreateData.name )
        , ( "description", Encode.string bigbitCreateData.description )
        , ( "tags", Encode.list <| List.map Encode.string bigbitCreateData.tags )
        , ( "tagInput", Encode.string bigbitCreateData.tagInput )
        ]


{-| BigbitCreateData `cacheDecoder`.
-}
bigbitCreateDataCacheDecoder : Decode.Decoder BigbitCreateData
bigbitCreateDataCacheDecoder =
    decode BigbitCreateData
        |> required "name" Decode.string
        |> required "description" Decode.string
        |> required "tags" (Decode.list Decode.string)
        |> required "tagInput" Decode.string
