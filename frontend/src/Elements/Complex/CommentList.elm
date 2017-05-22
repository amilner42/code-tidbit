module Elements.Complex.CommentList exposing (..)

import Date
import Date.Format
import DefaultServices.Editable as Editable
import DefaultServices.InfixFunctions exposing (..)
import DefaultServices.Util as Util
import Dict
import Html exposing (Html, div, span, text, textarea)
import Html.Attributes exposing (class, classList, placeholder, value)
import Html.Events exposing (onInput, onClick)
import Models.QA exposing (..)
import ProjectTypeAliases exposing (..)


type Msg
    = OnNewCommentTextInput CommentText


type alias Model =
    { commentEdits : Dict.Dict CommentID (Editable.Editable CommentText)
    , newCommentText : CommentText
    }


type alias RenderConfig msg comment =
    { msgTagger : Msg -> msg
    , commentBoxRenderConfig : CommentBoxRenderConfig msg (Comment comment)
    , comments : List (Comment comment)
    , submitNewComment : CommentText -> msg
    , small : Bool
    }


view : RenderConfig msg comment -> Model -> Html msg
view config model =
    div
        [ class "comment-list" ]
        [ div
            [ classList [ ( "comments-wrapper", True ), ( "small", config.small ) ] ]
            [ Util.keyedDiv
                [ class "comments" ]
                (if List.isEmpty config.comments then
                    [ ( "no-comments-text"
                      , span [ class "no-comments-text" ] [ text "No Comments" ]
                      )
                    ]
                 else
                    List.map
                        (\comment -> ( comment.id, commentBoxView config.commentBoxRenderConfig comment ))
                        config.comments
                )
            ]
        , textarea
            [ class "new-comment-textarea"
            , onInput <| config.msgTagger << OnNewCommentTextInput
            , placeholder "Add Comment..."
            , value model.newCommentText
            ]
            []
        , div
            (Util.maybeAttributes
                [ Just <|
                    classList
                        [ ( "submit-comment", True )
                        , ( "disabled", Util.isNothing <| Util.justNonBlankString model.newCommentText )
                        ]
                , Util.justNonBlankString model.newCommentText ||> onClick << config.submitNewComment
                ]
            )
            [ text "Submit Comment" ]
        ]


type alias CommentBoxRenderConfig msg comment =
    { onClickComment : Comment comment -> msg }


commentBoxView : CommentBoxRenderConfig msg (Comment comment) -> Comment comment -> Html msg
commentBoxView config comment =
    div
        [ class "comment-box" ]
        [ span [ class "comment-box-text" ] [ text <| comment.commentText ]
        , div
            [ class "comment-box-bottom" ]
            [ span
                [ class "email" ]
                [ text <| comment.authorEmail ]
            , span
                [ class "date" ]
                [ text <| Date.Format.format "%m/%d/%Y" comment.createdAt ]
            ]
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        OnNewCommentTextInput newCommentText ->
            ( { model | newCommentText = newCommentText }, Cmd.none )
