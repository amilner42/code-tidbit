module JSON.QA exposing (..)

import DefaultServices.Util as Util
import JSON.Range
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Json.Encode as Encode
import Models.QA exposing (..)


{-| `SnipbitQA` decoder.
-}
snipbitQADecoder : Decode.Decoder SnipbitQA
snipbitQADecoder =
    decoder JSON.Range.decoder


{-| `BigbitQA` decoder.
-}
bigbitQADecoder : Decode.Decoder BigbitQA
bigbitQADecoder =
    decoder bigbitCodePointerDecoder


{-| `QA` decoder.
-}
decoder : Decode.Decoder codePointerType -> Decode.Decoder (QA codePointerType)
decoder decodeCodePointer =
    decode QA
        |> required "id" Decode.string
        |> required "tidbitID" Decode.string
        |> required "tidbitAuthor" Decode.string
        |> required "questions" (Decode.list <| questionDecoder decodeCodePointer)
        |> required "questionComments" (Decode.list questionCommentDecoder)
        |> required "answers" (Decode.list answerDecoder)
        |> required "answerComments" (Decode.list answerCommentDecoder)


{-| `Question` decoder.
-}
questionDecoder : Decode.Decoder codePointerType -> Decode.Decoder (Question codePointerType)
questionDecoder decodeCodePointer =
    decode Question
        |> required "id" Decode.string
        |> required "questionText" Decode.string
        |> required "authorID" Decode.string
        |> required "authorEmail" Decode.string
        |> required "codePointer" decodeCodePointer
        |> required "upvotes" votesDecoder
        |> required "downvotes" votesDecoder
        |> required "pinned" Decode.bool
        |> required "lastModified" Util.dateDecoder
        |> required "createdAt" Util.dateDecoder


{-| `Answer` decoder.
-}
answerDecoder : Decode.Decoder Answer
answerDecoder =
    decode Answer
        |> required "id" Decode.string
        |> required "questionID" Decode.string
        |> required "answerText" Decode.string
        |> required "authorID" Decode.string
        |> required "authorEmail" Decode.string
        |> required "upvotes" votesDecoder
        |> required "downvotes" votesDecoder
        |> required "pinned" Decode.bool
        |> required "lastModified" Util.dateDecoder
        |> required "createdAt" Util.dateDecoder


{-| `QuestionComment` decoder.
-}
questionCommentDecoder : Decode.Decoder QuestionComment
questionCommentDecoder =
    decode QuestionComment
        |> required "id" Decode.string
        |> required "questionID" Decode.string
        |> required "commentText" Decode.string
        |> required "authorID" Decode.string
        |> required "authorEmail" Decode.string
        |> required "lastModified" Util.dateDecoder
        |> required "createdAt" Util.dateDecoder


{-| `AnswerComment` decoder.
-}
answerCommentDecoder : Decode.Decoder AnswerComment
answerCommentDecoder =
    decode AnswerComment
        |> required "id" Decode.string
        |> required "questionID" Decode.string
        |> required "commentText" Decode.string
        |> required "authorID" Decode.string
        |> required "authorEmail" Decode.string
        |> required "lastModified" Util.dateDecoder
        |> required "createdAt" Util.dateDecoder
        |> required "answerID" Decode.string


{-| For decoding the upvotes/downvotes pair.
-}
votesDecoder : Decode.Decoder ( Bool, Int )
votesDecoder =
    Decode.map2 (,) (Decode.index 0 Decode.bool) (Decode.index 1 Decode.int)


{-| `BigbitCodePointer` decoder.
-}
bigbitCodePointerDecoder : Decode.Decoder BigbitCodePointer
bigbitCodePointerDecoder =
    decode BigbitCodePointer
        |> required "file" Decode.string
        |> required "range" JSON.Range.decoder


{-| `BigbitCodePointer` encoder.
-}
bigbitCodePointerEncoder : BigbitCodePointer -> Encode.Value
bigbitCodePointerEncoder codePointer =
    Encode.object
        [ ( "file", Encode.string codePointer.file )
        , ( "range", JSON.Range.encoder codePointer.range )
        ]