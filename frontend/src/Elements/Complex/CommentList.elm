module Elements.Complex.CommentList exposing (..)

import Date.Format
import DefaultServices.Editable as Editable
import DefaultServices.InfixFunctions exposing (..)
import DefaultServices.TextFields as TextFields
import DefaultServices.Util as Util
import Dict
import Html exposing (Html, div, i, span, text)
import Html.Attributes exposing (class, classList, defaultValue, disabled, placeholder)
import Html.Events exposing (onClick, onInput)
import Models.QA exposing (..)
import ProjectTypeAliases exposing (..)
import Set


type Msg
    = OnNewCommentTextInput CommentText
    | AddToDeletingComments CommentID
    | StartEditing CommentID CommentText
    | CancelEditing CommentID
    | OnEditCommentInput CommentID CommentText


type alias Model =
    { commentEdits : Dict.Dict CommentID (Editable.Editable CommentText)
    , newCommentText : CommentText
    , deletingComments : Set.Set CommentID
    }


type alias RenderConfig msg comment =
    { subMsg : Msg -> msg
    , textFieldKeyTracker : TextFields.KeyTracker
    , userID : Maybe UserID
    , comments : List (Comment comment)
    , isSmall : Bool
    , submitCommentRequestInProgress : Bool
    , deleteCommentRequestInProgress : CommentID -> Bool
    , editCommentRequestInProgress : CommentID -> Bool
    , goToComment : Comment comment -> msg
    , newComment : CommentText -> msg
    , editComment : CommentID -> CommentText -> msg
    , deleteComment : CommentID -> msg
    }


view : RenderConfig msg comment -> Model -> Html msg
view config model =
    let
        isLoggedIn =
            Util.isNotNothing config.userID

        justReadyComment =
            Util.justNonblankStringInRange 1 300 model.newCommentText

        isReadyComment =
            Util.isNotNothing justReadyComment
    in
    div
        [ class "comment-list" ]
        [ div
            [ classList [ ( "comments-wrapper", True ), ( "small", config.isSmall ) ] ]
            [ Util.keyedDiv
                [ class "comments" ]
                (if List.isEmpty config.comments then
                    [ ( "no-comments-text"
                      , span [ class "no-comments-text" ] [ text "No Comments" ]
                      )
                    ]
                 else
                    List.map
                        (\comment -> ( comment.id, commentBoxView config model comment ))
                        config.comments
                )
            ]
        , TextFields.textarea
            config.textFieldKeyTracker
            "new-comment"
            [ classList
                [ ( "new-comment-textarea", True )
                , ( "cursor-progress", config.submitCommentRequestInProgress )
                ]
            , onInput <| config.subMsg << OnNewCommentTextInput
            , placeholder <|
                if isLoggedIn then
                    "Add comment..."
                else
                    "Sign up or login to comment..."
            , defaultValue model.newCommentText
            , disabled <| not isLoggedIn || config.submitCommentRequestInProgress
            ]
        , Util.limitCharsText 300 model.newCommentText
        , div
            (Util.maybeAttributes
                [ Just <|
                    classList
                        [ ( "submit-comment", True )
                        , ( "disabled", not isReadyComment || not isLoggedIn )
                        , ( "cursor-progress", config.submitCommentRequestInProgress )
                        ]
                , case ( isLoggedIn, justReadyComment ) of
                    ( True, Just comment ) ->
                        Just <| onClick <| config.newComment comment

                    _ ->
                        Nothing
                ]
            )
            [ text "Submit Comment" ]
        ]


commentBoxView : RenderConfig msg comment -> Model -> Comment comment -> Html msg
commentBoxView config { deletingComments, commentEdits } comment =
    let
        isBeingDeleted =
            Set.member comment.id deletingComments

        maybeCommentEdit =
            Dict.get comment.id commentEdits

        isCommentAuthor =
            config.userID == Just comment.authorID
    in
    div
        [ class "comment-box" ]
        [ case maybeCommentEdit of
            Just commentEdit ->
                TextFields.textarea
                    config.textFieldKeyTracker
                    ("edit-comment-" ++ toString comment.id)
                    [ classList
                        [ ( "comment-box-text-edit-mode", True )
                        , ( "cursor-progress", config.editCommentRequestInProgress comment.id )
                        ]
                    , placeholder "Edit comment..."
                    , disabled <| config.editCommentRequestInProgress comment.id
                    , defaultValue <| Editable.getBuffer commentEdit
                    , onInput <| config.subMsg << OnEditCommentInput comment.id
                    ]

            Nothing ->
                span [ class "comment-box-text" ] [ text <| comment.commentText ]
        , div
            [ class "comment-box-bottom" ]
            [ if isCommentAuthor then
                div
                    [ class "author-icons" ]
                    (case maybeCommentEdit of
                        Just commentEdit ->
                            [ i
                                (Util.maybeAttributes
                                    [ Just <|
                                        classList
                                            [ ( "material-icons cancel-edit", True )
                                            , ( "cursor-progress", config.editCommentRequestInProgress comment.id )
                                            ]
                                    , if config.editCommentRequestInProgress comment.id then
                                        Nothing
                                      else
                                        Just <| onClick <| config.subMsg <| CancelEditing comment.id
                                    ]
                                )
                                [ text "cancel" ]
                            , i
                                (Util.maybeAttributes
                                    [ Just <|
                                        classList
                                            [ ( "material-icons submit-edit", True )
                                            , ( "not-allowed"
                                              , Editable.getBuffer commentEdit
                                                    |> Util.justNonBlankString
                                                    |> Util.isNothing
                                              )
                                            , ( "cursor-progress", config.editCommentRequestInProgress comment.id )
                                            ]
                                    , Editable.getBuffer commentEdit
                                        |> Util.justNonBlankString
                                        ||> config.editComment comment.id
                                        ||> onClick
                                    ]
                                )
                                [ text "check_circle" ]
                            ]

                        Nothing ->
                            [ i
                                [ classList
                                    [ ( "material-icons delete-comment", True )
                                    , ( "delete-warning", isBeingDeleted )
                                    , ( "cursor-progress", config.deleteCommentRequestInProgress comment.id )
                                    ]
                                , onClick <|
                                    if isBeingDeleted then
                                        config.deleteComment comment.id
                                    else
                                        config.subMsg <| AddToDeletingComments comment.id
                                ]
                                [ text <|
                                    if isBeingDeleted then
                                        "delete_forever"
                                    else
                                        "delete"
                                ]
                            , i
                                (Util.maybeAttributes
                                    [ Just <|
                                        classList
                                            [ ( "material-icons edit-comment", True )
                                            , ( "cursor-progress"
                                              , config.deleteCommentRequestInProgress comment.id
                                              )
                                            ]
                                    , if config.deleteCommentRequestInProgress comment.id then
                                        Nothing
                                      else
                                        Just <|
                                            onClick <|
                                                config.subMsg <|
                                                    StartEditing comment.id comment.commentText
                                    ]
                                )
                                [ text "edit_mode" ]
                            ]
                    )
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

        StartEditing commentID commentText ->
            -- If already editing then do nothing.
            if Dict.member commentID model.commentEdits then
                ( model, Cmd.none )
            else
                ( { model | commentEdits = Dict.insert commentID (Editable.newEditing commentText) model.commentEdits }
                , Cmd.none
                )

        CancelEditing commentID ->
            ( { model
                | commentEdits = Dict.remove commentID model.commentEdits
                , deletingComments = Set.remove commentID model.deletingComments
              }
            , Cmd.none
            )

        OnEditCommentInput commentID commentText ->
            ( { model
                | commentEdits =
                    Dict.update
                        commentID
                        (Maybe.map (\commentEdit -> Editable.setBuffer commentEdit commentText))
                        model.commentEdits
              }
            , Cmd.none
            )
