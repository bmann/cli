-- | File sync, IPFS-style
module Fission.CLI.Command.Up (command, up) where

import           RIO
import           RIO.Directory
import           RIO.Process (HasProcessContext)

import           Data.Has
import           Options.Applicative.Simple hiding (command)

import           Fission.Internal.Constraint
import           Fission.Internal.Exception

import qualified Fission.Storage.IPFS as IPFS
import qualified Fission.IPFS.Types   as IPFS
import qualified Fission.Web.Client   as Client

import           Fission.CLI.Command.Up.Types as Up
import qualified Fission.CLI.Display.Error    as Error
import qualified Fission.CLI.IPFS.Pin         as CLI.Pin
import qualified Fission.CLI.DNS              as CLI.DNS
import           Fission.CLI.Config.Types
import qualified Fission.CLI.Config.Guard    as Config.Guard

-- | The command to attach to the CLI tree
command :: MonadIO m
        => HasLogFunc        cfg
        => HasProcessContext cfg
        => Has IPFS.BinPath  cfg
        => Has IPFS.Timeout  cfg
        => Has Client.Runner cfg
        => cfg
        -> CommandM (m ())
command cfg =
  addCommand
    "up"
    "Keep your current working directory up"
    (\options -> runRIO cfg $ Config.Guard.ensureLocalConfig $ up options)
    parseOptions

-- | Sync the current working directory to the server over IPFS
up :: MonadRIO cfg m
   => HasLoggedIn  cfg
   => Up.Options
   -> m ()
up Up.Options {..} = handleWith_ Error.put' do
  absPath <- liftIO $ makeAbsolute path
  cid     <- liftE $ IPFS.addDir path

  logDebug $ "Starting single IPFS add locally of " <> displayShow absPath

  unless dnsOnly do
    void . liftE $ CLI.Pin.run cid

  liftE $ CLI.DNS.update cid

parseOptions :: Parser Up.Options
parseOptions = do
  dnsOnly <- switch $ mconcat
    [ long "dns-only"
    , help "Only update DNS (skip file sync)"
    ]

  path <- strArgument $ mconcat
    [ metavar "PATH"
    , help    "The file path of the assets or directory to sync"
    , value   "./"
    ]

  return Up.Options {..}

