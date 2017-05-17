module Elements.AnswerQuestion exposing (..)

import DefaultServices.Util as Util
import Elements.Markdown as Markdown
import Html exposing (Html, div, text, textarea)
import Html.Attributes exposing (class, classList, value, placeholder)
import Html.Events exposing (onInput, onClick)
import Models.QA exposing (..)
import ProjectTypeAliases exposing (..)


{-| The Model for the `AnswerQuestion` element.
-}
type alias Model codePointer =
    { newAnswer : NewAnswer
    , forQuestion : Question codePointer
    }


{-| The Msg for the `AnswerQuestion` element.
-}
type Msg
    = ToggleShowQuestion
    | TogglePreviewMarkdown
    | OnAnswerTextInput AnswerText


{-| The config for rendering the `AnswerQuestion` element.
-}
type alias RenderConfig msg =
    { msgTagger : Msg -> msg
    , answerQuestion : AnswerText -> msg
    }


{-| The view for the `AnswerQuestion` element.
-}
answerQuestion : RenderConfig msg -> Model codePointer -> Html msg
answerQuestion config model =
    let
        { previewMarkdown, showQuestion, answerText } =
            model.newAnswer

        maybeReadyAnswer =
            Util.justNonBlankString answerText

        isAnswerReady =
            Util.isNotNothing maybeReadyAnswer
    in
        div
            [ class "answer-question" ]
            [ div
                [ classList
                    [ ( "display-question", True )
                    , ( "hidden", previewMarkdown )
                    ]
                , onClick <| config.msgTagger ToggleShowQuestion
                ]
                [ text <|
                    if showQuestion then
                        "Hide Question"
                    else
                        "Show Question"
                ]
            , Markdown.githubMarkdown
                [ classList
                    [ ( "question", True )
                    , ( "hidden", previewMarkdown || not showQuestion )
                    ]
                ]
                model.forQuestion.questionText
            , div
                [ classList
                    [ ( "preview-markdown", True )
                    , ( "previewing-markdown", previewMarkdown )
                    , ( "hiding-question", not showQuestion )
                    ]
                , onClick <| config.msgTagger TogglePreviewMarkdown
                ]
                [ text <|
                    if previewMarkdown then
                        "Close Preview"
                    else
                        "Markdown Preview"
                ]
            , Util.markdownOr
                previewMarkdown
                answerText
                (textarea
                    [ classList [ ( "hiding-question", not showQuestion ) ]
                    , placeholder "Answer Question"
                    , onInput (config.msgTagger << OnAnswerTextInput)
                    , value answerText
                    ]
                    []
                )
            , div
                (Util.maybeAttributes
                    [ Just <|
                        classList
                            [ ( "answer-question-submit", True )
                            , ( "hidden", previewMarkdown )
                            , ( "not-ready", not isAnswerReady )
                            ]
                    , Maybe.map (onClick << config.answerQuestion) maybeReadyAnswer
                    ]
                )
                [ text "Submit Answer" ]
            ]


{-| The update for the `AnswerQuestion` element.
-}
update : Msg -> Model codePointer -> ( Model codePointer, Cmd Msg )
update msg model =
    case msg of
        ToggleShowQuestion ->
            ( updateNewAnswer
                (\newAnswer -> { newAnswer | showQuestion = not newAnswer.showQuestion })
                model
            , Cmd.none
            )

        TogglePreviewMarkdown ->
            ( updateNewAnswer
                (\newAnswer -> { newAnswer | previewMarkdown = not newAnswer.previewMarkdown })
                model
            , Cmd.none
            )

        OnAnswerTextInput answerText ->
            ( updateNewAnswer
                (\newAnswer -> { newAnswer | answerText = answerText })
                model
            , Cmd.none
            )


{-| Helper for updating the nested field `newAnswer`.
-}
updateNewAnswer : (NewAnswer -> NewAnswer) -> Model codePointer -> Model codePointer
updateNewAnswer updater model =
    { model | newAnswer = updater model.newAnswer }
