{-# LANGUAGE OverloadedStrings #-}
module Handler.Live where

import           Import
import           Yesod.Auth
import qualified Data.Text  as T
-------------------------------------------------------------------------------------------------------------
getLiveR :: Handler Html
getLiveR = do
  muser    <- maybeAuth
  mgroup   <- getMaybeGroup muser
  let permissions = getPermissions mgroup
      group       = (groupName . entityVal) <$> mgroup
  -------------------------------------------------------------------------------------------------------------------      
  boards    <- runDB $ selectList ([]::[Filter Board]) []
  let f (Entity _ b) | boardHidden b || (isJust (boardViewAccess b) && group /= boardViewAccess b) = Just $ boardName b
                     | otherwise                                                                = Nothing
      boards'  = catMaybes $ map f boards
  posts     <- runDB $ selectList [PostDeletedByOp ==. False, PostBoard /<-. boards'] [Desc PostDate, LimitTo 15]
  postFiles <- forM posts $ \e -> runDB $ selectList [AttachedfileParentId ==. entityKey e] []
  let postsAndFiles = zip posts postFiles
  -------------------------------------------------------------------------------------------------------------------
  nameOfTheBoard  <- extraSiteName <$> getExtra
  msgrender       <- getMessageRender
  defaultLayout $ do
    setUltDestCurrent
    setTitle $ toHtml $ T.concat [nameOfTheBoard, " — ", msgrender MsgLatestPosts]
    $(widgetFile "live")
  
