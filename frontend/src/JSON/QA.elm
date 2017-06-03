module JSON.QA exposing (..)

import DefaultServices.Editable as Editable
import DefaultServices.Util as Util
import JSON.Range
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Json.Encode as Encode
import Models.QA exposing (..)
import Set


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


{-| `QAState` encoder.
-}
qaStateEncoder : (codePointer -> Encode.Value) -> QAState codePointer -> Encode.Value
qaStateEncoder codePointerEncoder =
    Util.encodeStringDict <| tidbitQAStateEncoder codePointerEncoder


{-| `TidbitQAState` encoder.
-}
tidbitQAStateEncoder : (codePointer -> Encode.Value) -> TidbitQAState codePointer -> Encode.Value
tidbitQAStateEncoder codePointerEncoder qaState =
    let
        editableStringEncoder editableString =
            Editable.encoder Encode.string editableString

        stringToStringDictEncoder dict =
            Util.encodeStringDict Encode.string dict

        stringToEditableStringDictEncoder dict =
            Util.encodeStringDict editableStringEncoder dict

        newQuestionEncoder { questionText, codePointer } =
            Encode.object
                [ ( "questionText", Encode.string questionText )
                , ( "codePointer", Util.justValueOrNull codePointerEncoder codePointer )
                , ( "previewMarkdown", Encode.null )
                ]

        questionEditEncoder { questionText, codePointer } =
            Encode.object
                [ ( "questionText", editableStringEncoder questionText )
                , ( "codePointer", Editable.encoder codePointerEncoder codePointer )
                , ( "previewMarkdown", Encode.null )
                ]

        newAnswerEncoder { answerText, previewMarkdown, showQuestion } =
            Encode.object
                [ ( "answerText", Encode.string answerText )
                , ( "previewMarkdown", Encode.null )
                , ( "showQuestion", Encode.null )
                ]

        answerEditEncoder { answerText, previewMarkdown, showQuestion } =
            Encode.object
                [ ( "answerText", editableStringEncoder answerText )
                , ( "previewMarkdown", Encode.null )
                , ( "showQuestion", Encode.null )
                ]
    in
        Encode.object
            [ ( "browsingCodePointer", Util.justValueOrNull codePointerEncoder qaState.browsingCodePointer )
            , ( "newQuestion", newQuestionEncoder qaState.newQuestion )
            , ( "questionEdits", Util.encodeStringDict questionEditEncoder qaState.questionEdits )
            , ( "newAnswers", Util.encodeStringDict newAnswerEncoder qaState.newAnswers )
            , ( "answerEdits", Util.encodeStringDict answerEditEncoder qaState.answerEdits )
            , ( "newQuestionComments", stringToStringDictEncoder qaState.newQuestionComments )
            , ( "newAnswerComments", stringToStringDictEncoder qaState.newAnswerComments )
            , ( "questionCommentEdits", stringToEditableStringDictEncoder qaState.questionCommentEdits )
            , ( "answerCommentEdits", stringToEditableStringDictEncoder qaState.answerCommentEdits )
            , ( "deletingComments", Encode.null )
            , ( "deletingAnswers", Encode.null )
            ]


{-| `QAState` decoder.
-}
qaStateDecoder : Decode.Decoder codePointer -> Decode.Decoder (QAState codePointer)
qaStateDecoder codePointerDecoder =
    Util.decodeStringDict <| tidbitQAStateDecoder codePointerDecoder


{-| `TidbitQAState` decoder.
-}
tidbitQAStateDecoder : Decode.Decoder codePointer -> Decode.Decoder (TidbitQAState codePointer)
tidbitQAStateDecoder codePointerDecoder =
    let
        editableStringDecoder =
            Editable.decoder Decode.string

        stringToStringDictDecoder =
            Util.decodeStringDict Decode.string

        stringToEditableStringDictDecoder =
            Util.decodeStringDict editableStringDecoder

        newQuestionDecoder =
            decode NewQuestion
                |> required "questionText" Decode.string
                |> required "codePointer" (Decode.maybe codePointerDecoder)
                |> hardcoded False

        questionEditDecoder =
            decode QuestionEdit
                |> required "questionText" editableStringDecoder
                |> required "codePointer" (Editable.decoder codePointerDecoder)
                |> hardcoded False

        newAnswerDecoder =
            decode NewAnswer
                |> required "answerText" Decode.string
                |> hardcoded False
                |> hardcoded True

        answerEditDecoder =
            decode AnswerEdit
                |> required "answerText" editableStringDecoder
                |> hardcoded False
                |> hardcoded True
    in
        decode TidbitQAState
            |> required "browsingCodePointer" (Decode.maybe codePointerDecoder)
            |> required "newQuestion" newQuestionDecoder
            |> required "questionEdits" (Util.decodeStringDict questionEditDecoder)
            |> required "newAnswers" (Util.decodeStringDict newAnswerDecoder)
            |> required "answerEdits" (Util.decodeStringDict answerEditDecoder)
            |> required "newQuestionComments" stringToStringDictDecoder
            |> required "newAnswerComments" stringToStringDictDecoder
            |> required "questionCommentEdits" stringToEditableStringDictDecoder
            |> required "answerCommentEdits" stringToEditableStringDictDecoder
            |> hardcoded Set.empty
            |> hardcoded Set.empty
