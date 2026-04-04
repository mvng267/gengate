from app.models.base import Base
from app.models.blocks import Block
from app.models.conversation_members import ConversationMember
from app.models.conversations import Conversation
from app.models.device_keys import DeviceKey
from app.models.devices import Device
from app.models.friend_requests import FriendRequest
from app.models.friendships import Friendship
from app.models.location_share_audience import LocationShareAudience
from app.models.location_shares import LocationShare
from app.models.message_attachments import MessageAttachment
from app.models.message_device_keys import MessageDeviceKey
from app.models.messages import Message
from app.models.moment_media import MomentMedia
from app.models.moment_reactions import MomentReaction
from app.models.moments import Moment
from app.models.notifications import Notification
from app.models.profiles import Profile
from app.models.sessions import Session
from app.models.user_location_snapshots import UserLocationSnapshot
from app.models.user_recovery_material import UserRecoveryMaterial
from app.models.users import User

all_models = (
    Base,
    User,
    Profile,
    Device,
    Session,
    FriendRequest,
    Friendship,
    Block,
    Moment,
    MomentMedia,
    MomentReaction,
    Conversation,
    ConversationMember,
    Message,
    MessageDeviceKey,
    MessageAttachment,
    DeviceKey,
    UserRecoveryMaterial,
    LocationShare,
    LocationShareAudience,
    UserLocationSnapshot,
    Notification,
)
