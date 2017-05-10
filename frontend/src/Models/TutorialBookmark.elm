module Models.TutorialBookmark exposing (..)


{-| For tracking where we currently are in a tidbit.
-}
type TutorialBookmark
    = Introduction
    | FrameNumber Int
    | Conclusion
