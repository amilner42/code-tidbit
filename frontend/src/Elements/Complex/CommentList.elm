module Elements.Complex.CommentList exposing (..)

import Date
import Date.Format
import DefaultServices.Editable as Editable
import DefaultServices.InfixFunctions exposing (..)
import DefaultServices.Util as Util
import Dict
import Html exposing (Html, div, span, i, text, textarea)
import Html.Attributes exposing (class, classList, placeholder, value)
import Html.Events exposing (onInput, onClick)
import Models.QA exposing (..)
import ProjectTypeAliases exposing (..)
import Set


type Msg
    = OnNewCommentTextInput CommentText
    | AddToDeletingComments CommentID


type alias Model =
    { commentEdits : Dict.Dict CommentID (Editable.Editable CommentText)
    , newCommentText : CommentText
    , deletingComments : Set.Set CommentID
    }


type alias RenderConfig msg comment =
    { msgTagger : Msg -> msg
    , userID : Maybe UserID
    , small : Bool
    , comments : List (Comment comment)
    , submitNewComment : CommentText -> msg
    , onClickComment : Comment comment -> msg
    , deleteComment : CommentID -> msg
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
                        (\comment -> ( comment.id, commentBoxView config model.deletingComments comment ))
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


commentBoxView : RenderConfig msg comment -> Set.Set CommentID -> Comment comment -> Html msg
commentBoxView config deletingComments comment =
    let
        isBeingDeleted =
            Set.member comment.id deletingComments

        isCommentAuthor =
            config.userID == (Just comment.authorID)
    in
        div
            [ class "comment-box" ]
            [ span [ class "comment-box-text" ] [ text <| comment.commentText ]
            , div
                [ class "comment-box-bottom" ]
                [ if isCommentAuthor then
                    div
                        [ class "author-icons" ]
                        [ i
                            [ classList
                                [ ( "material-icons delete-comment", True )
                                , ( "delete-warning", isBeingDeleted )
                                ]
                            , onClick <|
                                if isBeingDeleted then
                                    config.deleteComment comment.id
                                else
                                    config.msgTagger <| AddToDeletingComments comment.id
                            ]
                            [ text <|
                                if isBeingDeleted then
                                    "delete_forever"
                                else
                                    "delete"
                            ]
                        , i [ class "material-icons edit-comment" ] [ text "edit_mode" ]
                        ]
                  else
                    span
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

        AddToDeletingComments commentID ->
            ( { model | deletingComments = Set.insert commentID model.deletingComments }, Cmd.none )
