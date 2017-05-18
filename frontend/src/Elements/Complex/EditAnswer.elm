module Elements.Complex.EditAnswer exposing (..)

import DefaultServices.Editable as Editable
import DefaultServices.Util as Util
import Elements.Simple.Markdown as Markdown
import Html exposing (Html, div, text, textarea)
import Html.Attributes exposing (class, classList, placeholder, value)
import Html.Events exposing (onInput, onClick)
import Models.QA exposing (..)
import ProjectTypeAliases exposing (..)


type alias Model codePointer =
    { answerEdit : AnswerEdit
    , forQuestion : Question codePointer
    }


type Msg
    = ToggleShowQuestion
    | TogglePreviewMarkdown
    | OnAnswerTextInput AnswerText


type alias RenderConfig msg =
    { msgTagger : Msg -> msg
    , editAnswer : AnswerText -> msg
    }


view : RenderConfig msg -> Model codePointer -> Html msg
view config model =
    let
        { previewMarkdown, showQuestion } =
            model.answerEdit

        answerText =
            Editable.getBuffer model.answerEdit.answerText

        maybeReadyAnswer =
            Util.justNonBlankString answerText

        isAnswerReady =
            Util.isNotNothing maybeReadyAnswer
    in
        div
            [ class "edit-answer" ]
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
            , Markdown.view
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
                    , placeholder "Edit Answer Text"
                    , value answerText
                    , onInput (config.msgTagger << OnAnswerTextInput)
                    ]
                    []
                )
            , div
                (Util.maybeAttributes
                    [ Just <|
                        classList
                            [ ( "edit-answer-submit", True )
                            , ( "not-ready", not isAnswerReady )
                            , ( "hidden", previewMarkdown )
                            ]
                    , Maybe.map
                        (onClick << config.editAnswer)
                        maybeReadyAnswer
                    ]
                )
                [ text "Update Answer" ]
            ]


update : Msg -> Model codePointer -> ( Model codePointer, Cmd Msg )
update msg model =
    case msg of
        ToggleShowQuestion ->
            ( updateAnswerEdit
                (\answerEdit -> { answerEdit | showQuestion = not answerEdit.showQuestion })
                model
            , Cmd.none
            )

        TogglePreviewMarkdown ->
            ( updateAnswerEdit
                (\answerEdit -> { answerEdit | previewMarkdown = not answerEdit.previewMarkdown })
                model
            , Cmd.none
            )

        OnAnswerTextInput answerText ->
            ( updateAnswerEdit
                (\answerEdit -> { answerEdit | answerText = Editable.setBuffer answerEdit.answerText answerText })
                model
            , Cmd.none
            )


{-| Helper for updating the nested field `answerEdit`.
-}
updateAnswerEdit : (AnswerEdit -> AnswerEdit) -> Model codePointer -> Model codePointer
updateAnswerEdit updater model =
    { model | answerEdit = updater model.answerEdit }
