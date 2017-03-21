module JSON.FileStructure exposing (..)

import DefaultServices.Util as Util
import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Elements.FileStructure exposing (..)


{-| Encodes a file given the metadata encoder.
-}
encodeFile : (fileMetadata -> Encode.Value) -> File fileMetadata -> Encode.Value
encodeFile fileMetadataEncoder (File content fileMetadata) =
    Encode.object
        [ ( "content", Encode.string content )
        , ( "fileMetadata", fileMetadataEncoder fileMetadata )
        ]


{-| Encodes a folder given the metadata encoders.
-}
encodeFolder :
    (folderMetadata -> Encode.Value)
    -> (fileMetadata -> Encode.Value)
    -> Folder folderMetadata fileMetadata
    -> Encode.Value
encodeFolder folderMetadataEncoder fileMetadataEncoder (Folder files folders folderMetadata) =
    Encode.object
        [ ( "files", Util.encodeStringDict (encodeFile fileMetadataEncoder) files )
        , ( "folders", Util.encodeStringDict (encodeFolder folderMetadataEncoder fileMetadataEncoder) folders )
        , ( "folderMetadata", folderMetadataEncoder folderMetadata )
        ]


{-| Encodes the FS given the metadata encoders.
-}
encodeFS :
    (fsMetadata -> Encode.Value)
    -> (folderMetadata -> Encode.Value)
    -> (fileMetadata -> Encode.Value)
    -> FileStructure fsMetadata folderMetadata fileMetadata
    -> Encode.Value
encodeFS fsMetadataEncoder folderMetadataEncoder fileMetadataEncoder (FileStructure rootFolder fsMetadata) =
    Encode.object
        [ ( "rootFolder", encodeFolder folderMetadataEncoder fileMetadataEncoder rootFolder )
        , ( "fsMetadata", fsMetadataEncoder fsMetadata )
        ]


{-| Decodes a file given the metadata decoder.
-}
decodeFile : Decode.Decoder fileMetadata -> Decode.Decoder (File fileMetadata)
decodeFile fileMetadataDecoder =
    decode File
        |> required "content" Decode.string
        |> required "fileMetadata" fileMetadataDecoder


{-| Decodes a folder given the metadata decoders.
-}
decodeFolder :
    Decode.Decoder folderMetadata
    -> Decode.Decoder fileMetadata
    -> Decode.Decoder (Folder folderMetadata fileMetadata)
decodeFolder folderMetadataDecoder fileMetadataDecoder =
    decode Folder
        |> required "files" (Util.decodeStringDict (decodeFile fileMetadataDecoder))
        |> required "folders" (Util.decodeStringDict (Decode.lazy (\_ -> (decodeFolder folderMetadataDecoder fileMetadataDecoder))))
        |> required "folderMetadata" folderMetadataDecoder


{-| Decodes the FS given the metadata decoders.
-}
decodeFS :
    Decode.Decoder fsMetadata
    -> Decode.Decoder folderMetadata
    -> Decode.Decoder fileMetadata
    -> Decode.Decoder (FileStructure fsMetadata folderMetadata fileMetadata)
decodeFS fsMetadataDecoder folderMetadataDecoder fileMetadataDecoder =
    decode FileStructure
        |> required "rootFolder" (decodeFolder folderMetadataDecoder fileMetadataDecoder)
        |> required "fsMetadata" fsMetadataDecoder
