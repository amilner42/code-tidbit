module JSON.FileStructure exposing (..)

import DefaultServices.Util as Util
import Elements.FileStructure exposing (..)
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Json.Encode as Encode


{-| `File` encoder.

Requires encoder for `fileMetadata`.
-}
fileEncoder : (fileMetadata -> Encode.Value) -> File fileMetadata -> Encode.Value
fileEncoder fileMetadataEncoder (File content fileMetadata) =
    Encode.object
        [ ( "content", Encode.string content )
        , ( "fileMetadata", fileMetadataEncoder fileMetadata )
        ]


{-| `Folder` encoder.

Requires encoder for `folderMetadata` and `fileMetadata`.
-}
folderEncoder :
    (folderMetadata -> Encode.Value)
    -> (fileMetadata -> Encode.Value)
    -> Folder folderMetadata fileMetadata
    -> Encode.Value
folderEncoder folderMetadataEncoder fileMetadataEncoder (Folder files folders folderMetadata) =
    Encode.object
        [ ( "files", Util.encodeStringDict (fileEncoder fileMetadataEncoder) files )
        , ( "folders", Util.encodeStringDict (folderEncoder folderMetadataEncoder fileMetadataEncoder) folders )
        , ( "folderMetadata", folderMetadataEncoder folderMetadata )
        ]


{-| `FileStructure` encoder.

Requires `fsMetadata`/`folderMetadata`/`fileMetadata` encoders.
-}
encoder :
    (fsMetadata -> Encode.Value)
    -> (folderMetadata -> Encode.Value)
    -> (fileMetadata -> Encode.Value)
    -> FileStructure fsMetadata folderMetadata fileMetadata
    -> Encode.Value
encoder fsMetadataEncoder folderMetadataEncoder fileMetadataEncoder (FileStructure rootFolder fsMetadata) =
    Encode.object
        [ ( "rootFolder", folderEncoder folderMetadataEncoder fileMetadataEncoder rootFolder )
        , ( "fsMetadata", fsMetadataEncoder fsMetadata )
        ]


{-| `File` decoder.

Requires `fileMetadata` encoder.
-}
fileDecoder : Decode.Decoder fileMetadata -> Decode.Decoder (File fileMetadata)
fileDecoder fileMetadataDecoder =
    decode File
        |> required "content" Decode.string
        |> required "fileMetadata" fileMetadataDecoder


{-| `Folder` decoder.

Requires decoder for `fileMetadata` and `folderMetadata`.
-}
folderDecoder :
    Decode.Decoder folderMetadata
    -> Decode.Decoder fileMetadata
    -> Decode.Decoder (Folder folderMetadata fileMetadata)
folderDecoder folderMetadataDecoder fileMetadataDecoder =
    decode Folder
        |> required "files" (Util.decodeStringDict (fileDecoder fileMetadataDecoder))
        |> required "folders" (Util.decodeStringDict (Decode.lazy (\_ -> (folderDecoder folderMetadataDecoder fileMetadataDecoder))))
        |> required "folderMetadata" folderMetadataDecoder


{-| `FileStructure` decoder.

Requires `fsMetadata`/`folderMetadata`/`fileMetadata` decoders.
-}
decoder :
    Decode.Decoder fsMetadata
    -> Decode.Decoder folderMetadata
    -> Decode.Decoder fileMetadata
    -> Decode.Decoder (FileStructure fsMetadata folderMetadata fileMetadata)
decoder fsMetadataDecoder folderMetadataDecoder fileMetadataDecoder =
    decode FileStructure
        |> required "rootFolder" (folderDecoder folderMetadataDecoder fileMetadataDecoder)
        |> required "fsMetadata" fsMetadataDecoder
