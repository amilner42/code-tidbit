module Elements.Complex.AnswerQuestion exposing (..)

import Api
import DefaultServices.InfixFunctions exposing (..)
import DefaultServices.TextFields as TextFields
import DefaultServices.Util as Util
import Elements.Simple.Markdown as Markdown
import ExplanatoryBlurbs exposing (answerQuestionPlaceholder)
import Html exposing (Html, div, text)
import Html.Attributes exposing (class, classList, defaultValue, disabled, placeholder)
import Html.Events exposing (onClick, onInput)
import Models.ApiError exposing (ApiError)
import Models.QA exposing (..)
import Models.RequestTracker as RT
import Models.Route as Route
import ProjectTypeAliases exposing (..)


type alias Model qaType qaStateType =
    { qa : QA qaType
    , qaState : QAState qaStateType
    , apiRequestTracker : RT.RequestTracker
    }


type Msg
    = ToggleShowQuestion TidbitID QuestionID
    | TogglePreviewMarkdown TidbitID QuestionID
    | OnAnswerTextInput TidbitID QuestionID AnswerText
    | AnswerQuestion TidbitID QuestionID RT.TrackedRequest (AnswerID -> Route.Route) (Api.Endpoint Answer Msg)
    | OnAnswerQuestionSuccess TidbitID QuestionID RT.TrackedRequest (AnswerID -> Route.Route) Answer
    | OnAnswerQuestionFailure ApiError


type alias RenderConfig msg =
    { subMsg : Msg -> msg
    , textFieldKeyTracker : TextFields.KeyTracker
    , tidbitID : TidbitID
    , questionID : QuestionID
    , answerQuestionRequestInProgress : Bool
    , allAnswersND : Route.NavigationData msg
    , answerQuestion : ( AnswerText -> Api.Endpoint Answer Msg, RT.TrackedRequest )
    , answerRoute : AnswerID -> Route.Route
    }


view : RenderConfig msg -> Model qaType qaStateType -> Html msg
view config model =
    case model.qa.questions |> getQuestion config.questionID of
        -- This element shouldn't be displayed if question is non-existant.
        Nothing ->
            Util.hiddenDiv

        Just { questionText } ->
            let
                { previewMarkdown, showQuestion, answerText } =
                    getNewAnswer config.tidbitID config.questionID model.qaState
                        ?> defaultNewAnswer

                maybeReadyAnswer =
                    Util.justNonblankStringInRange 1 1000 answerText

                isAnswerReady =
                    Util.isNotNothing maybeReadyAnswer
            in
            div
                [ class "answer-question" ]
                [ Route.navigationNode
                    (Just config.allAnswersND)
                    [ class "link-nav-node" ]
                    [ div
                        [ class "link qa-top-right-link" ]
                        [ text "see all answers" ]
                    ]
                , div
                    [ classList
                        [ ( "display-question", True )
                        , ( "hidden", previewMarkdown )
                        ]
                    , onClick <| config.subMsg <| ToggleShowQuestion config.tidbitID config.questionID
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
                    questionText
                , div
                    [ classList
                        [ ( "preview-markdown", True )
                        , ( "previewing-markdown", previewMarkdown )
                        , ( "hiding-question", not showQuestion )
                        ]
                    , onClick <| config.subMsg <| TogglePreviewMarkdown config.tidbitID config.questionID
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
                    (div
                        []
                        [ TextFields.textarea
                            config.textFieldKeyTracker
                            "answer-question"
                            [ classList
                                [ ( "hiding-question", not showQuestion )
                                , ( "cursor-progress", config.answerQuestionRequestInProgress )
                                ]
                            , placeholder answerQuestionPlaceholder
                            , disabled config.answerQuestionRequestInProgress
                            , onInput (config.subMsg << OnAnswerTextInput config.tidbitID config.questionID)
                            , defaultValue answerText
                            ]
                        , Util.limitCharsText 1000 answerText
                        ]
                    )
                , div
                    (Util.maybeAttributes
                        [ Just <|
                            classList
                                [ ( "answer-question-submit", True )
                                , ( "hidden", previewMarkdown )
                                , ( "not-ready", not isAnswerReady )
                                , ( "cursor-progress", config.answerQuestionRequestInProgress )
                                ]
                        , maybeReadyAnswer
                            ||> (onClick
                                    << config.subMsg
                                    << AnswerQuestion
                                        config.tidbitID
                                        config.questionID
                                        (Tuple.second config.answerQuestion)
                                        config.answerRoute
                                    << Tuple.first config.answerQuestion
                                )
                        ]
                    )
                    [ text "Submit Answer" ]
                ]


update : Msg -> Model qaType qaStateType -> ( Model qaType qaStateType, Cmd Msg )
update msg model =
    let
        updateNewAnswerState tidbitID questionID updater =
            { model
                | qaState =
                    updateNewAnswer
                        tidbitID
                        questionID
                        (\newAnswer -> newAnswer ?> defaultNewAnswer |> updater |> Just)
                        model.qaState
            }
    in
    case msg of
        ToggleShowQuestion tidbitID questionID ->
            ( updateNewAnswerState
                tidbitID
                questionID
                (\newAnswer -> { newAnswer | showQuestion = not newAnswer.showQuestion })
            , Cmd.none
            )

        TogglePreviewMarkdown tidbitID questionID ->
            ( updateNewAnswerState
                tidbitID
                questionID
                (\newAnswer -> { newAnswer | previewMarkdown = not newAnswer.previewMarkdown })
            , Cmd.none
            )

        OnAnswerTextInput tidbitID questionID answerText ->
            ( updateNewAnswerState
                tidbitID
                questionID
                (\newAnswer -> { newAnswer | answerText = answerText })
            , Cmd.none
            )

        AnswerQuestion tidbitID questionID trackedRequest answerRoute endPoint ->
            if RT.isMakingRequest model.apiRequestTracker trackedRequest then
                ( model, Cmd.none )
            else
                ( { model | apiRequestTracker = RT.startRequest trackedRequest model.apiRequestTracker }
                , endPoint OnAnswerQuestionFailure (OnAnswerQuestionSuccess tidbitID questionID trackedRequest answerRoute)
                )

        OnAnswerQuestionSuccess tidbitID questionID trackedRequest answerRoute answer ->
            let
                qa =
                    model.qa
            in
            ( { model
                | qa = { qa | answers = sortRateableContent <| answer :: qa.answers }
                , qaState = model.qaState |> updateNewAnswer tidbitID questionID (always Nothing)
                , apiRequestTracker = RT.finishRequest trackedRequest model.apiRequestTracker
              }
            , Route.navigateTo <| answerRoute answer.id
            )

        OnAnswerQuestionFailure _ ->
            ( model, Cmd.none )
