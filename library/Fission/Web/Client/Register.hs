module Fission.Web.Client.Register
  ( register
  , verify
  ) where

import RIO

import Servant
import Servant.Client

import qualified Fission.User.Registration.Types as User
import           Fission.Web.Routes              (UserRoute)

import           Fission.Internal.Orphanage.BasicAuthData ()

verify   :: BasicAuthData     -> ClientM Bool
register :: User.Registration -> ClientM ()

register :<|> verify = client (Proxy :: Proxy UserRoute)

