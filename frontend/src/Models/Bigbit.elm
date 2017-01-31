module Models.Bigbit exposing (..)

import Dict
import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Models.HighlightedComment as HighlightedComment
import Models.FileStructure as FS


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
    , introduction : String
    , conclusion : String
    , fs :
        FS.FileStructure
            { activeFile : Maybe FS.Path
            , openFS : Bool
            }
            { isExpanded : Bool
            }
            {}
    }


{-| BigbitCreateData `cacheEncoder`.
-}
bigbitCreateDataCacheEncoder : BigbitCreateData -> Encode.Value
bigbitCreateDataCacheEncoder bigbitCreateData =
    let
        -- TODO make encoder for code.
        encodeCode code =
            Encode.null
    in
        Encode.object
            [ ( "name", Encode.string bigbitCreateData.name )
            , ( "description", Encode.string bigbitCreateData.description )
            , ( "tags", Encode.list <| List.map Encode.string bigbitCreateData.tags )
            , ( "tagInput", Encode.string bigbitCreateData.tagInput )
            , ( "introduction", Encode.string bigbitCreateData.introduction )
            , ( "conclusion", Encode.string bigbitCreateData.conclusion )
            , ( "fs", encodeCode bigbitCreateData.fs )
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
        |> required "introduction" Decode.string
        |> required "conclusion" Decode.string
        |> hardcoded
            (FS.emptyFS
                { activeFile = Nothing, openFS = True }
                { isExpanded = True }
            )
