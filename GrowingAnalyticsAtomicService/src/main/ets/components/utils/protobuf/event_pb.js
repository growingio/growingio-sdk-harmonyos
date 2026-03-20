/*eslint-disable block-scoped-var, id-length, no-control-regex, no-magic-numbers, no-prototype-builtins, no-redeclare, no-shadow, no-var, sort-vars*/
import { index } from "@ohos/protobufjs";
import Long from 'long';

const $protobuf = index;
$protobuf.util.Long=Long;
$protobuf.configure();

// Common aliases
const $Reader = $protobuf.Reader, $Writer = $protobuf.Writer, $util = $protobuf.util;

// Exported root namespace
const $root = $protobuf.roots["default"] || ($protobuf.roots["default"] = {});

export const event_pb = $root.event_pb = (() => {

    /**
     * Namespace event_pb.
     * @exports event_pb
     * @namespace
     */
    const event_pb = {};

    event_pb.EventV3Dto = (function() {

        /**
         * Properties of an EventV3Dto.
         * @memberof event_pb
         * @interface IEventV3Dto
         * @property {string|null} [deviceId] EventV3Dto deviceId
         * @property {string|null} [userId] EventV3Dto userId
         * @property {string|null} [gioId] EventV3Dto gioId
         * @property {string|null} [sessionId] EventV3Dto sessionId
         * @property {string|null} [dataSourceId] EventV3Dto dataSourceId
         * @property {event_pb.EventType|null} [eventType] EventV3Dto eventType
         * @property {string|null} [platform] EventV3Dto platform
         * @property {number|Long|null} [timestamp] EventV3Dto timestamp
         * @property {string|null} [domain] EventV3Dto domain
         * @property {string|null} [path] EventV3Dto path
         * @property {string|null} [query] EventV3Dto query
         * @property {string|null} [title] EventV3Dto title
         * @property {string|null} [referralPage] EventV3Dto referralPage
         * @property {number|Long|null} [globalSequenceId] EventV3Dto globalSequenceId
         * @property {number|null} [eventSequenceId] EventV3Dto eventSequenceId
         * @property {number|null} [screenHeight] EventV3Dto screenHeight
         * @property {number|null} [screenWidth] EventV3Dto screenWidth
         * @property {string|null} [language] EventV3Dto language
         * @property {string|null} [sdkVersion] EventV3Dto sdkVersion
         * @property {string|null} [appVersion] EventV3Dto appVersion
         * @property {Object.<string,string>|null} [extraSdk] EventV3Dto extraSdk
         * @property {string|null} [eventName] EventV3Dto eventName
         * @property {Object.<string,string>|null} [attributes] EventV3Dto attributes
         * @property {event_pb.IResourceItem|null} [resourceItem] EventV3Dto resourceItem
         * @property {string|null} [protocolType] EventV3Dto protocolType
         * @property {string|null} [textValue] EventV3Dto textValue
         * @property {string|null} [xpath] EventV3Dto xpath
         * @property {number|null} [index] EventV3Dto index
         * @property {string|null} [hyperlink] EventV3Dto hyperlink
         * @property {string|null} [urlScheme] EventV3Dto urlScheme
         * @property {string|null} [appState] EventV3Dto appState
         * @property {string|null} [networkState] EventV3Dto networkState
         * @property {string|null} [appChannel] EventV3Dto appChannel
         * @property {string|null} [pageName] EventV3Dto pageName
         * @property {string|null} [platformVersion] EventV3Dto platformVersion
         * @property {string|null} [deviceBrand] EventV3Dto deviceBrand
         * @property {string|null} [deviceModel] EventV3Dto deviceModel
         * @property {string|null} [deviceType] EventV3Dto deviceType
         * @property {string|null} [operatingSystem] EventV3Dto operatingSystem
         * @property {string|null} [appName] EventV3Dto appName
         * @property {number|null} [latitude] EventV3Dto latitude
         * @property {number|null} [longitude] EventV3Dto longitude
         * @property {string|null} [imei] EventV3Dto imei
         * @property {string|null} [androidId] EventV3Dto androidId
         * @property {string|null} [oaid] EventV3Dto oaid
         * @property {string|null} [googleAdvertisingId] EventV3Dto googleAdvertisingId
         * @property {string|null} [idfa] EventV3Dto idfa
         * @property {string|null} [idfv] EventV3Dto idfv
         * @property {string|null} [orientation] EventV3Dto orientation
         * @property {string|null} [projectKey] EventV3Dto projectKey
         * @property {number|Long|null} [sendTime] EventV3Dto sendTime
         * @property {string|null} [userKey] EventV3Dto userKey
         * @property {string|null} [xcontent] EventV3Dto xcontent
         * @property {string|null} [timezoneOffset] EventV3Dto timezoneOffset
         */

        /**
         * Constructs a new EventV3Dto.
         * @memberof event_pb
         * @classdesc Represents an EventV3Dto.
         * @implements IEventV3Dto
         * @constructor
         * @param {event_pb.IEventV3Dto=} [properties] Properties to set
         */
        function EventV3Dto(properties) {
            this.extraSdk = {};
            this.attributes = {};
            if (properties)
                for (let keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                    if (properties[keys[i]] != null)
                        this[keys[i]] = properties[keys[i]];
        }

        /**
         * EventV3Dto deviceId.
         * @member {string} deviceId
         * @memberof event_pb.EventV3Dto
         * @instance
         */
        EventV3Dto.prototype.deviceId = "";

        /**
         * EventV3Dto userId.
         * @member {string} userId
         * @memberof event_pb.EventV3Dto
         * @instance
         */
        EventV3Dto.prototype.userId = "";

        /**
         * EventV3Dto gioId.
         * @member {string} gioId
         * @memberof event_pb.EventV3Dto
         * @instance
         */
        EventV3Dto.prototype.gioId = "";

        /**
         * EventV3Dto sessionId.
         * @member {string} sessionId
         * @memberof event_pb.EventV3Dto
         * @instance
         */
        EventV3Dto.prototype.sessionId = "";

        /**
         * EventV3Dto dataSourceId.
         * @member {string} dataSourceId
         * @memberof event_pb.EventV3Dto
         * @instance
         */
        EventV3Dto.prototype.dataSourceId = "";

        /**
         * EventV3Dto eventType.
         * @member {event_pb.EventType} eventType
         * @memberof event_pb.EventV3Dto
         * @instance
         */
        EventV3Dto.prototype.eventType = 0;

        /**
         * EventV3Dto platform.
         * @member {string} platform
         * @memberof event_pb.EventV3Dto
         * @instance
         */
        EventV3Dto.prototype.platform = "";

        /**
         * EventV3Dto timestamp.
         * @member {number|Long} timestamp
         * @memberof event_pb.EventV3Dto
         * @instance
         */
        EventV3Dto.prototype.timestamp = $util.Long ? $util.Long.fromBits(0,0,false) : 0;

        /**
         * EventV3Dto domain.
         * @member {string} domain
         * @memberof event_pb.EventV3Dto
         * @instance
         */
        EventV3Dto.prototype.domain = "";

        /**
         * EventV3Dto path.
         * @member {string} path
         * @memberof event_pb.EventV3Dto
         * @instance
         */
        EventV3Dto.prototype.path = "";

        /**
         * EventV3Dto query.
         * @member {string} query
         * @memberof event_pb.EventV3Dto
         * @instance
         */
        EventV3Dto.prototype.query = "";

        /**
         * EventV3Dto title.
         * @member {string} title
         * @memberof event_pb.EventV3Dto
         * @instance
         */
        EventV3Dto.prototype.title = "";

        /**
         * EventV3Dto referralPage.
         * @member {string} referralPage
         * @memberof event_pb.EventV3Dto
         * @instance
         */
        EventV3Dto.prototype.referralPage = "";

        /**
         * EventV3Dto globalSequenceId.
         * @member {number|Long} globalSequenceId
         * @memberof event_pb.EventV3Dto
         * @instance
         */
        EventV3Dto.prototype.globalSequenceId = $util.Long ? $util.Long.fromBits(0,0,false) : 0;

        /**
         * EventV3Dto eventSequenceId.
         * @member {number} eventSequenceId
         * @memberof event_pb.EventV3Dto
         * @instance
         */
        EventV3Dto.prototype.eventSequenceId = 0;

        /**
         * EventV3Dto screenHeight.
         * @member {number} screenHeight
         * @memberof event_pb.EventV3Dto
         * @instance
         */
        EventV3Dto.prototype.screenHeight = 0;

        /**
         * EventV3Dto screenWidth.
         * @member {number} screenWidth
         * @memberof event_pb.EventV3Dto
         * @instance
         */
        EventV3Dto.prototype.screenWidth = 0;

        /**
         * EventV3Dto language.
         * @member {string} language
         * @memberof event_pb.EventV3Dto
         * @instance
         */
        EventV3Dto.prototype.language = "";

        /**
         * EventV3Dto sdkVersion.
         * @member {string} sdkVersion
         * @memberof event_pb.EventV3Dto
         * @instance
         */
        EventV3Dto.prototype.sdkVersion = "";

        /**
         * EventV3Dto appVersion.
         * @member {string} appVersion
         * @memberof event_pb.EventV3Dto
         * @instance
         */
        EventV3Dto.prototype.appVersion = "";

        /**
         * EventV3Dto extraSdk.
         * @member {Object.<string,string>} extraSdk
         * @memberof event_pb.EventV3Dto
         * @instance
         */
        EventV3Dto.prototype.extraSdk = $util.emptyObject;

        /**
         * EventV3Dto eventName.
         * @member {string} eventName
         * @memberof event_pb.EventV3Dto
         * @instance
         */
        EventV3Dto.prototype.eventName = "";

        /**
         * EventV3Dto attributes.
         * @member {Object.<string,string>} attributes
         * @memberof event_pb.EventV3Dto
         * @instance
         */
        EventV3Dto.prototype.attributes = $util.emptyObject;

        /**
         * EventV3Dto resourceItem.
         * @member {event_pb.IResourceItem|null|undefined} resourceItem
         * @memberof event_pb.EventV3Dto
         * @instance
         */
        EventV3Dto.prototype.resourceItem = null;

        /**
         * EventV3Dto protocolType.
         * @member {string} protocolType
         * @memberof event_pb.EventV3Dto
         * @instance
         */
        EventV3Dto.prototype.protocolType = "";

        /**
         * EventV3Dto textValue.
         * @member {string} textValue
         * @memberof event_pb.EventV3Dto
         * @instance
         */
        EventV3Dto.prototype.textValue = "";

        /**
         * EventV3Dto xpath.
         * @member {string} xpath
         * @memberof event_pb.EventV3Dto
         * @instance
         */
        EventV3Dto.prototype.xpath = "";

        /**
         * EventV3Dto index.
         * @member {number} index
         * @memberof event_pb.EventV3Dto
         * @instance
         */
        EventV3Dto.prototype.index = 0;

        /**
         * EventV3Dto hyperlink.
         * @member {string} hyperlink
         * @memberof event_pb.EventV3Dto
         * @instance
         */
        EventV3Dto.prototype.hyperlink = "";

        /**
         * EventV3Dto urlScheme.
         * @member {string} urlScheme
         * @memberof event_pb.EventV3Dto
         * @instance
         */
        EventV3Dto.prototype.urlScheme = "";

        /**
         * EventV3Dto appState.
         * @member {string} appState
         * @memberof event_pb.EventV3Dto
         * @instance
         */
        EventV3Dto.prototype.appState = "";

        /**
         * EventV3Dto networkState.
         * @member {string} networkState
         * @memberof event_pb.EventV3Dto
         * @instance
         */
        EventV3Dto.prototype.networkState = "";

        /**
         * EventV3Dto appChannel.
         * @member {string} appChannel
         * @memberof event_pb.EventV3Dto
         * @instance
         */
        EventV3Dto.prototype.appChannel = "";

        /**
         * EventV3Dto pageName.
         * @member {string} pageName
         * @memberof event_pb.EventV3Dto
         * @instance
         */
        EventV3Dto.prototype.pageName = "";

        /**
         * EventV3Dto platformVersion.
         * @member {string} platformVersion
         * @memberof event_pb.EventV3Dto
         * @instance
         */
        EventV3Dto.prototype.platformVersion = "";

        /**
         * EventV3Dto deviceBrand.
         * @member {string} deviceBrand
         * @memberof event_pb.EventV3Dto
         * @instance
         */
        EventV3Dto.prototype.deviceBrand = "";

        /**
         * EventV3Dto deviceModel.
         * @member {string} deviceModel
         * @memberof event_pb.EventV3Dto
         * @instance
         */
        EventV3Dto.prototype.deviceModel = "";

        /**
         * EventV3Dto deviceType.
         * @member {string} deviceType
         * @memberof event_pb.EventV3Dto
         * @instance
         */
        EventV3Dto.prototype.deviceType = "";

        /**
         * EventV3Dto operatingSystem.
         * @member {string} operatingSystem
         * @memberof event_pb.EventV3Dto
         * @instance
         */
        EventV3Dto.prototype.operatingSystem = "";

        /**
         * EventV3Dto appName.
         * @member {string} appName
         * @memberof event_pb.EventV3Dto
         * @instance
         */
        EventV3Dto.prototype.appName = "";

        /**
         * EventV3Dto latitude.
         * @member {number} latitude
         * @memberof event_pb.EventV3Dto
         * @instance
         */
        EventV3Dto.prototype.latitude = 0;

        /**
         * EventV3Dto longitude.
         * @member {number} longitude
         * @memberof event_pb.EventV3Dto
         * @instance
         */
        EventV3Dto.prototype.longitude = 0;

        /**
         * EventV3Dto imei.
         * @member {string} imei
         * @memberof event_pb.EventV3Dto
         * @instance
         */
        EventV3Dto.prototype.imei = "";

        /**
         * EventV3Dto androidId.
         * @member {string} androidId
         * @memberof event_pb.EventV3Dto
         * @instance
         */
        EventV3Dto.prototype.androidId = "";

        /**
         * EventV3Dto oaid.
         * @member {string} oaid
         * @memberof event_pb.EventV3Dto
         * @instance
         */
        EventV3Dto.prototype.oaid = "";

        /**
         * EventV3Dto googleAdvertisingId.
         * @member {string} googleAdvertisingId
         * @memberof event_pb.EventV3Dto
         * @instance
         */
        EventV3Dto.prototype.googleAdvertisingId = "";

        /**
         * EventV3Dto idfa.
         * @member {string} idfa
         * @memberof event_pb.EventV3Dto
         * @instance
         */
        EventV3Dto.prototype.idfa = "";

        /**
         * EventV3Dto idfv.
         * @member {string} idfv
         * @memberof event_pb.EventV3Dto
         * @instance
         */
        EventV3Dto.prototype.idfv = "";

        /**
         * EventV3Dto orientation.
         * @member {string} orientation
         * @memberof event_pb.EventV3Dto
         * @instance
         */
        EventV3Dto.prototype.orientation = "";

        /**
         * EventV3Dto projectKey.
         * @member {string} projectKey
         * @memberof event_pb.EventV3Dto
         * @instance
         */
        EventV3Dto.prototype.projectKey = "";

        /**
         * EventV3Dto sendTime.
         * @member {number|Long} sendTime
         * @memberof event_pb.EventV3Dto
         * @instance
         */
        EventV3Dto.prototype.sendTime = $util.Long ? $util.Long.fromBits(0,0,false) : 0;

        /**
         * EventV3Dto userKey.
         * @member {string} userKey
         * @memberof event_pb.EventV3Dto
         * @instance
         */
        EventV3Dto.prototype.userKey = "";

        /**
         * EventV3Dto xcontent.
         * @member {string} xcontent
         * @memberof event_pb.EventV3Dto
         * @instance
         */
        EventV3Dto.prototype.xcontent = "";

        /**
         * EventV3Dto timezoneOffset.
         * @member {string} timezoneOffset
         * @memberof event_pb.EventV3Dto
         * @instance
         */
        EventV3Dto.prototype.timezoneOffset = "";

        /**
         * Creates a new EventV3Dto instance using the specified properties.
         * @function create
         * @memberof event_pb.EventV3Dto
         * @static
         * @param {event_pb.IEventV3Dto=} [properties] Properties to set
         * @returns {event_pb.EventV3Dto} EventV3Dto instance
         */
        EventV3Dto.create = function create(properties) {
            return new EventV3Dto(properties);
        };

        /**
         * Encodes the specified EventV3Dto message. Does not implicitly {@link event_pb.EventV3Dto.verify|verify} messages.
         * @function encode
         * @memberof event_pb.EventV3Dto
         * @static
         * @param {event_pb.IEventV3Dto} message EventV3Dto message or plain object to encode
         * @param {$protobuf.Writer} [writer] Writer to encode to
         * @returns {$protobuf.Writer} Writer
         */
        EventV3Dto.encode = function encode(message, writer) {
            if (!writer)
                writer = $Writer.create();
            if (message.deviceId != null && Object.hasOwnProperty.call(message, "deviceId"))
                writer.uint32(/* id 1, wireType 2 =*/10).string(message.deviceId);
            if (message.userId != null && Object.hasOwnProperty.call(message, "userId"))
                writer.uint32(/* id 2, wireType 2 =*/18).string(message.userId);
            if (message.gioId != null && Object.hasOwnProperty.call(message, "gioId"))
                writer.uint32(/* id 3, wireType 2 =*/26).string(message.gioId);
            if (message.sessionId != null && Object.hasOwnProperty.call(message, "sessionId"))
                writer.uint32(/* id 4, wireType 2 =*/34).string(message.sessionId);
            if (message.dataSourceId != null && Object.hasOwnProperty.call(message, "dataSourceId"))
                writer.uint32(/* id 5, wireType 2 =*/42).string(message.dataSourceId);
            if (message.eventType != null && Object.hasOwnProperty.call(message, "eventType"))
                writer.uint32(/* id 6, wireType 0 =*/48).int32(message.eventType);
            if (message.platform != null && Object.hasOwnProperty.call(message, "platform"))
                writer.uint32(/* id 7, wireType 2 =*/58).string(message.platform);
            if (message.timestamp != null && Object.hasOwnProperty.call(message, "timestamp"))
                writer.uint32(/* id 8, wireType 0 =*/64).int64(message.timestamp);
            if (message.domain != null && Object.hasOwnProperty.call(message, "domain"))
                writer.uint32(/* id 9, wireType 2 =*/74).string(message.domain);
            if (message.path != null && Object.hasOwnProperty.call(message, "path"))
                writer.uint32(/* id 10, wireType 2 =*/82).string(message.path);
            if (message.query != null && Object.hasOwnProperty.call(message, "query"))
                writer.uint32(/* id 11, wireType 2 =*/90).string(message.query);
            if (message.title != null && Object.hasOwnProperty.call(message, "title"))
                writer.uint32(/* id 12, wireType 2 =*/98).string(message.title);
            if (message.referralPage != null && Object.hasOwnProperty.call(message, "referralPage"))
                writer.uint32(/* id 13, wireType 2 =*/106).string(message.referralPage);
            if (message.globalSequenceId != null && Object.hasOwnProperty.call(message, "globalSequenceId"))
                writer.uint32(/* id 14, wireType 0 =*/112).int64(message.globalSequenceId);
            if (message.eventSequenceId != null && Object.hasOwnProperty.call(message, "eventSequenceId"))
                writer.uint32(/* id 15, wireType 0 =*/120).int32(message.eventSequenceId);
            if (message.screenHeight != null && Object.hasOwnProperty.call(message, "screenHeight"))
                writer.uint32(/* id 16, wireType 0 =*/128).int32(message.screenHeight);
            if (message.screenWidth != null && Object.hasOwnProperty.call(message, "screenWidth"))
                writer.uint32(/* id 17, wireType 0 =*/136).int32(message.screenWidth);
            if (message.language != null && Object.hasOwnProperty.call(message, "language"))
                writer.uint32(/* id 18, wireType 2 =*/146).string(message.language);
            if (message.sdkVersion != null && Object.hasOwnProperty.call(message, "sdkVersion"))
                writer.uint32(/* id 19, wireType 2 =*/154).string(message.sdkVersion);
            if (message.appVersion != null && Object.hasOwnProperty.call(message, "appVersion"))
                writer.uint32(/* id 20, wireType 2 =*/162).string(message.appVersion);
            if (message.extraSdk != null && Object.hasOwnProperty.call(message, "extraSdk"))
                for (let keys = Object.keys(message.extraSdk), i = 0; i < keys.length; ++i)
                    writer.uint32(/* id 21, wireType 2 =*/170).fork().uint32(/* id 1, wireType 2 =*/10).string(keys[i]).uint32(/* id 2, wireType 2 =*/18).string(message.extraSdk[keys[i]]).ldelim();
            if (message.eventName != null && Object.hasOwnProperty.call(message, "eventName"))
                writer.uint32(/* id 22, wireType 2 =*/178).string(message.eventName);
            if (message.attributes != null && Object.hasOwnProperty.call(message, "attributes"))
                for (let keys = Object.keys(message.attributes), i = 0; i < keys.length; ++i)
                    writer.uint32(/* id 24, wireType 2 =*/194).fork().uint32(/* id 1, wireType 2 =*/10).string(keys[i]).uint32(/* id 2, wireType 2 =*/18).string(message.attributes[keys[i]]).ldelim();
            if (message.resourceItem != null && Object.hasOwnProperty.call(message, "resourceItem"))
                $root.event_pb.ResourceItem.encode(message.resourceItem, writer.uint32(/* id 25, wireType 2 =*/202).fork()).ldelim();
            if (message.protocolType != null && Object.hasOwnProperty.call(message, "protocolType"))
                writer.uint32(/* id 26, wireType 2 =*/210).string(message.protocolType);
            if (message.textValue != null && Object.hasOwnProperty.call(message, "textValue"))
                writer.uint32(/* id 27, wireType 2 =*/218).string(message.textValue);
            if (message.xpath != null && Object.hasOwnProperty.call(message, "xpath"))
                writer.uint32(/* id 28, wireType 2 =*/226).string(message.xpath);
            if (message.index != null && Object.hasOwnProperty.call(message, "index"))
                writer.uint32(/* id 29, wireType 0 =*/232).int32(message.index);
            if (message.hyperlink != null && Object.hasOwnProperty.call(message, "hyperlink"))
                writer.uint32(/* id 30, wireType 2 =*/242).string(message.hyperlink);
            if (message.urlScheme != null && Object.hasOwnProperty.call(message, "urlScheme"))
                writer.uint32(/* id 31, wireType 2 =*/250).string(message.urlScheme);
            if (message.appState != null && Object.hasOwnProperty.call(message, "appState"))
                writer.uint32(/* id 32, wireType 2 =*/258).string(message.appState);
            if (message.networkState != null && Object.hasOwnProperty.call(message, "networkState"))
                writer.uint32(/* id 33, wireType 2 =*/266).string(message.networkState);
            if (message.appChannel != null && Object.hasOwnProperty.call(message, "appChannel"))
                writer.uint32(/* id 34, wireType 2 =*/274).string(message.appChannel);
            if (message.pageName != null && Object.hasOwnProperty.call(message, "pageName"))
                writer.uint32(/* id 35, wireType 2 =*/282).string(message.pageName);
            if (message.platformVersion != null && Object.hasOwnProperty.call(message, "platformVersion"))
                writer.uint32(/* id 36, wireType 2 =*/290).string(message.platformVersion);
            if (message.deviceBrand != null && Object.hasOwnProperty.call(message, "deviceBrand"))
                writer.uint32(/* id 37, wireType 2 =*/298).string(message.deviceBrand);
            if (message.deviceModel != null && Object.hasOwnProperty.call(message, "deviceModel"))
                writer.uint32(/* id 38, wireType 2 =*/306).string(message.deviceModel);
            if (message.deviceType != null && Object.hasOwnProperty.call(message, "deviceType"))
                writer.uint32(/* id 39, wireType 2 =*/314).string(message.deviceType);
            if (message.operatingSystem != null && Object.hasOwnProperty.call(message, "operatingSystem"))
                writer.uint32(/* id 40, wireType 2 =*/322).string(message.operatingSystem);
            if (message.appName != null && Object.hasOwnProperty.call(message, "appName"))
                writer.uint32(/* id 42, wireType 2 =*/338).string(message.appName);
            if (message.latitude != null && Object.hasOwnProperty.call(message, "latitude"))
                writer.uint32(/* id 44, wireType 1 =*/353).double(message.latitude);
            if (message.longitude != null && Object.hasOwnProperty.call(message, "longitude"))
                writer.uint32(/* id 45, wireType 1 =*/361).double(message.longitude);
            if (message.imei != null && Object.hasOwnProperty.call(message, "imei"))
                writer.uint32(/* id 46, wireType 2 =*/370).string(message.imei);
            if (message.androidId != null && Object.hasOwnProperty.call(message, "androidId"))
                writer.uint32(/* id 47, wireType 2 =*/378).string(message.androidId);
            if (message.oaid != null && Object.hasOwnProperty.call(message, "oaid"))
                writer.uint32(/* id 48, wireType 2 =*/386).string(message.oaid);
            if (message.googleAdvertisingId != null && Object.hasOwnProperty.call(message, "googleAdvertisingId"))
                writer.uint32(/* id 49, wireType 2 =*/394).string(message.googleAdvertisingId);
            if (message.idfa != null && Object.hasOwnProperty.call(message, "idfa"))
                writer.uint32(/* id 50, wireType 2 =*/402).string(message.idfa);
            if (message.idfv != null && Object.hasOwnProperty.call(message, "idfv"))
                writer.uint32(/* id 51, wireType 2 =*/410).string(message.idfv);
            if (message.orientation != null && Object.hasOwnProperty.call(message, "orientation"))
                writer.uint32(/* id 52, wireType 2 =*/418).string(message.orientation);
            if (message.projectKey != null && Object.hasOwnProperty.call(message, "projectKey"))
                writer.uint32(/* id 53, wireType 2 =*/426).string(message.projectKey);
            if (message.sendTime != null && Object.hasOwnProperty.call(message, "sendTime"))
                writer.uint32(/* id 54, wireType 0 =*/432).int64(message.sendTime);
            if (message.userKey != null && Object.hasOwnProperty.call(message, "userKey"))
                writer.uint32(/* id 55, wireType 2 =*/442).string(message.userKey);
            if (message.xcontent != null && Object.hasOwnProperty.call(message, "xcontent"))
                writer.uint32(/* id 56, wireType 2 =*/450).string(message.xcontent);
            if (message.timezoneOffset != null && Object.hasOwnProperty.call(message, "timezoneOffset"))
                writer.uint32(/* id 57, wireType 2 =*/458).string(message.timezoneOffset);
            return writer;
        };

        /**
         * Encodes the specified EventV3Dto message, length delimited. Does not implicitly {@link event_pb.EventV3Dto.verify|verify} messages.
         * @function encodeDelimited
         * @memberof event_pb.EventV3Dto
         * @static
         * @param {event_pb.IEventV3Dto} message EventV3Dto message or plain object to encode
         * @param {$protobuf.Writer} [writer] Writer to encode to
         * @returns {$protobuf.Writer} Writer
         */
        EventV3Dto.encodeDelimited = function encodeDelimited(message, writer) {
            return this.encode(message, writer).ldelim();
        };

        /**
         * Decodes an EventV3Dto message from the specified reader or buffer.
         * @function decode
         * @memberof event_pb.EventV3Dto
         * @static
         * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
         * @param {number} [length] Message length if known beforehand
         * @returns {event_pb.EventV3Dto} EventV3Dto
         * @throws {Error} If the payload is not a reader or valid buffer
         * @throws {$protobuf.util.ProtocolError} If required fields are missing
         */
        EventV3Dto.decode = function decode(reader, length) {
            if (!(reader instanceof $Reader))
                reader = $Reader.create(reader);
            let end = length === undefined ? reader.len : reader.pos + length, message = new $root.event_pb.EventV3Dto(), key, value;
            while (reader.pos < end) {
                let tag = reader.uint32();
                switch (tag >>> 3) {
                case 1: {
                        message.deviceId = reader.string();
                        break;
                    }
                case 2: {
                        message.userId = reader.string();
                        break;
                    }
                case 3: {
                        message.gioId = reader.string();
                        break;
                    }
                case 4: {
                        message.sessionId = reader.string();
                        break;
                    }
                case 5: {
                        message.dataSourceId = reader.string();
                        break;
                    }
                case 6: {
                        message.eventType = reader.int32();
                        break;
                    }
                case 7: {
                        message.platform = reader.string();
                        break;
                    }
                case 8: {
                        message.timestamp = reader.int64();
                        break;
                    }
                case 9: {
                        message.domain = reader.string();
                        break;
                    }
                case 10: {
                        message.path = reader.string();
                        break;
                    }
                case 11: {
                        message.query = reader.string();
                        break;
                    }
                case 12: {
                        message.title = reader.string();
                        break;
                    }
                case 13: {
                        message.referralPage = reader.string();
                        break;
                    }
                case 14: {
                        message.globalSequenceId = reader.int64();
                        break;
                    }
                case 15: {
                        message.eventSequenceId = reader.int32();
                        break;
                    }
                case 16: {
                        message.screenHeight = reader.int32();
                        break;
                    }
                case 17: {
                        message.screenWidth = reader.int32();
                        break;
                    }
                case 18: {
                        message.language = reader.string();
                        break;
                    }
                case 19: {
                        message.sdkVersion = reader.string();
                        break;
                    }
                case 20: {
                        message.appVersion = reader.string();
                        break;
                    }
                case 21: {
                        if (message.extraSdk === $util.emptyObject)
                            message.extraSdk = {};
                        let end2 = reader.uint32() + reader.pos;
                        key = "";
                        value = "";
                        while (reader.pos < end2) {
                            let tag2 = reader.uint32();
                            switch (tag2 >>> 3) {
                            case 1:
                                key = reader.string();
                                break;
                            case 2:
                                value = reader.string();
                                break;
                            default:
                                reader.skipType(tag2 & 7);
                                break;
                            }
                        }
                        message.extraSdk[key] = value;
                        break;
                    }
                case 22: {
                        message.eventName = reader.string();
                        break;
                    }
                case 24: {
                        if (message.attributes === $util.emptyObject)
                            message.attributes = {};
                        let end2 = reader.uint32() + reader.pos;
                        key = "";
                        value = "";
                        while (reader.pos < end2) {
                            let tag2 = reader.uint32();
                            switch (tag2 >>> 3) {
                            case 1:
                                key = reader.string();
                                break;
                            case 2:
                                value = reader.string();
                                break;
                            default:
                                reader.skipType(tag2 & 7);
                                break;
                            }
                        }
                        message.attributes[key] = value;
                        break;
                    }
                case 25: {
                        message.resourceItem = $root.event_pb.ResourceItem.decode(reader, reader.uint32());
                        break;
                    }
                case 26: {
                        message.protocolType = reader.string();
                        break;
                    }
                case 27: {
                        message.textValue = reader.string();
                        break;
                    }
                case 28: {
                        message.xpath = reader.string();
                        break;
                    }
                case 29: {
                        message.index = reader.int32();
                        break;
                    }
                case 30: {
                        message.hyperlink = reader.string();
                        break;
                    }
                case 31: {
                        message.urlScheme = reader.string();
                        break;
                    }
                case 32: {
                        message.appState = reader.string();
                        break;
                    }
                case 33: {
                        message.networkState = reader.string();
                        break;
                    }
                case 34: {
                        message.appChannel = reader.string();
                        break;
                    }
                case 35: {
                        message.pageName = reader.string();
                        break;
                    }
                case 36: {
                        message.platformVersion = reader.string();
                        break;
                    }
                case 37: {
                        message.deviceBrand = reader.string();
                        break;
                    }
                case 38: {
                        message.deviceModel = reader.string();
                        break;
                    }
                case 39: {
                        message.deviceType = reader.string();
                        break;
                    }
                case 40: {
                        message.operatingSystem = reader.string();
                        break;
                    }
                case 42: {
                        message.appName = reader.string();
                        break;
                    }
                case 44: {
                        message.latitude = reader.double();
                        break;
                    }
                case 45: {
                        message.longitude = reader.double();
                        break;
                    }
                case 46: {
                        message.imei = reader.string();
                        break;
                    }
                case 47: {
                        message.androidId = reader.string();
                        break;
                    }
                case 48: {
                        message.oaid = reader.string();
                        break;
                    }
                case 49: {
                        message.googleAdvertisingId = reader.string();
                        break;
                    }
                case 50: {
                        message.idfa = reader.string();
                        break;
                    }
                case 51: {
                        message.idfv = reader.string();
                        break;
                    }
                case 52: {
                        message.orientation = reader.string();
                        break;
                    }
                case 53: {
                        message.projectKey = reader.string();
                        break;
                    }
                case 54: {
                        message.sendTime = reader.int64();
                        break;
                    }
                case 55: {
                        message.userKey = reader.string();
                        break;
                    }
                case 56: {
                        message.xcontent = reader.string();
                        break;
                    }
                case 57: {
                        message.timezoneOffset = reader.string();
                        break;
                    }
                default:
                    reader.skipType(tag & 7);
                    break;
                }
            }
            return message;
        };

        /**
         * Decodes an EventV3Dto message from the specified reader or buffer, length delimited.
         * @function decodeDelimited
         * @memberof event_pb.EventV3Dto
         * @static
         * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
         * @returns {event_pb.EventV3Dto} EventV3Dto
         * @throws {Error} If the payload is not a reader or valid buffer
         * @throws {$protobuf.util.ProtocolError} If required fields are missing
         */
        EventV3Dto.decodeDelimited = function decodeDelimited(reader) {
            if (!(reader instanceof $Reader))
                reader = new $Reader(reader);
            return this.decode(reader, reader.uint32());
        };

        /**
         * Verifies an EventV3Dto message.
         * @function verify
         * @memberof event_pb.EventV3Dto
         * @static
         * @param {Object.<string,*>} message Plain object to verify
         * @returns {string|null} `null` if valid, otherwise the reason why it is not
         */
        EventV3Dto.verify = function verify(message) {
            if (typeof message !== "object" || message === null)
                return "object expected";
            if (message.deviceId != null && message.hasOwnProperty("deviceId"))
                if (!$util.isString(message.deviceId))
                    return "deviceId: string expected";
            if (message.userId != null && message.hasOwnProperty("userId"))
                if (!$util.isString(message.userId))
                    return "userId: string expected";
            if (message.gioId != null && message.hasOwnProperty("gioId"))
                if (!$util.isString(message.gioId))
                    return "gioId: string expected";
            if (message.sessionId != null && message.hasOwnProperty("sessionId"))
                if (!$util.isString(message.sessionId))
                    return "sessionId: string expected";
            if (message.dataSourceId != null && message.hasOwnProperty("dataSourceId"))
                if (!$util.isString(message.dataSourceId))
                    return "dataSourceId: string expected";
            if (message.eventType != null && message.hasOwnProperty("eventType"))
                switch (message.eventType) {
                default:
                    return "eventType: enum value expected";
                case 0:
                case 1:
                case 2:
                case 3:
                case 4:
                case 5:
                case 6:
                case 7:
                case 8:
                case 9:
                case 10:
                case 11:
                    break;
                }
            if (message.platform != null && message.hasOwnProperty("platform"))
                if (!$util.isString(message.platform))
                    return "platform: string expected";
            if (message.timestamp != null && message.hasOwnProperty("timestamp"))
                if (!$util.isInteger(message.timestamp) && !(message.timestamp && $util.isInteger(message.timestamp.low) && $util.isInteger(message.timestamp.high)))
                    return "timestamp: integer|Long expected";
            if (message.domain != null && message.hasOwnProperty("domain"))
                if (!$util.isString(message.domain))
                    return "domain: string expected";
            if (message.path != null && message.hasOwnProperty("path"))
                if (!$util.isString(message.path))
                    return "path: string expected";
            if (message.query != null && message.hasOwnProperty("query"))
                if (!$util.isString(message.query))
                    return "query: string expected";
            if (message.title != null && message.hasOwnProperty("title"))
                if (!$util.isString(message.title))
                    return "title: string expected";
            if (message.referralPage != null && message.hasOwnProperty("referralPage"))
                if (!$util.isString(message.referralPage))
                    return "referralPage: string expected";
            if (message.globalSequenceId != null && message.hasOwnProperty("globalSequenceId"))
                if (!$util.isInteger(message.globalSequenceId) && !(message.globalSequenceId && $util.isInteger(message.globalSequenceId.low) && $util.isInteger(message.globalSequenceId.high)))
                    return "globalSequenceId: integer|Long expected";
            if (message.eventSequenceId != null && message.hasOwnProperty("eventSequenceId"))
                if (!$util.isInteger(message.eventSequenceId))
                    return "eventSequenceId: integer expected";
            if (message.screenHeight != null && message.hasOwnProperty("screenHeight"))
                if (!$util.isInteger(message.screenHeight))
                    return "screenHeight: integer expected";
            if (message.screenWidth != null && message.hasOwnProperty("screenWidth"))
                if (!$util.isInteger(message.screenWidth))
                    return "screenWidth: integer expected";
            if (message.language != null && message.hasOwnProperty("language"))
                if (!$util.isString(message.language))
                    return "language: string expected";
            if (message.sdkVersion != null && message.hasOwnProperty("sdkVersion"))
                if (!$util.isString(message.sdkVersion))
                    return "sdkVersion: string expected";
            if (message.appVersion != null && message.hasOwnProperty("appVersion"))
                if (!$util.isString(message.appVersion))
                    return "appVersion: string expected";
            if (message.extraSdk != null && message.hasOwnProperty("extraSdk")) {
                if (!$util.isObject(message.extraSdk))
                    return "extraSdk: object expected";
                let key = Object.keys(message.extraSdk);
                for (let i = 0; i < key.length; ++i)
                    if (!$util.isString(message.extraSdk[key[i]]))
                        return "extraSdk: string{k:string} expected";
            }
            if (message.eventName != null && message.hasOwnProperty("eventName"))
                if (!$util.isString(message.eventName))
                    return "eventName: string expected";
            if (message.attributes != null && message.hasOwnProperty("attributes")) {
                if (!$util.isObject(message.attributes))
                    return "attributes: object expected";
                let key = Object.keys(message.attributes);
                for (let i = 0; i < key.length; ++i)
                    if (!$util.isString(message.attributes[key[i]]))
                        return "attributes: string{k:string} expected";
            }
            if (message.resourceItem != null && message.hasOwnProperty("resourceItem")) {
                let error = $root.event_pb.ResourceItem.verify(message.resourceItem);
                if (error)
                    return "resourceItem." + error;
            }
            if (message.protocolType != null && message.hasOwnProperty("protocolType"))
                if (!$util.isString(message.protocolType))
                    return "protocolType: string expected";
            if (message.textValue != null && message.hasOwnProperty("textValue"))
                if (!$util.isString(message.textValue))
                    return "textValue: string expected";
            if (message.xpath != null && message.hasOwnProperty("xpath"))
                if (!$util.isString(message.xpath))
                    return "xpath: string expected";
            if (message.index != null && message.hasOwnProperty("index"))
                if (!$util.isInteger(message.index))
                    return "index: integer expected";
            if (message.hyperlink != null && message.hasOwnProperty("hyperlink"))
                if (!$util.isString(message.hyperlink))
                    return "hyperlink: string expected";
            if (message.urlScheme != null && message.hasOwnProperty("urlScheme"))
                if (!$util.isString(message.urlScheme))
                    return "urlScheme: string expected";
            if (message.appState != null && message.hasOwnProperty("appState"))
                if (!$util.isString(message.appState))
                    return "appState: string expected";
            if (message.networkState != null && message.hasOwnProperty("networkState"))
                if (!$util.isString(message.networkState))
                    return "networkState: string expected";
            if (message.appChannel != null && message.hasOwnProperty("appChannel"))
                if (!$util.isString(message.appChannel))
                    return "appChannel: string expected";
            if (message.pageName != null && message.hasOwnProperty("pageName"))
                if (!$util.isString(message.pageName))
                    return "pageName: string expected";
            if (message.platformVersion != null && message.hasOwnProperty("platformVersion"))
                if (!$util.isString(message.platformVersion))
                    return "platformVersion: string expected";
            if (message.deviceBrand != null && message.hasOwnProperty("deviceBrand"))
                if (!$util.isString(message.deviceBrand))
                    return "deviceBrand: string expected";
            if (message.deviceModel != null && message.hasOwnProperty("deviceModel"))
                if (!$util.isString(message.deviceModel))
                    return "deviceModel: string expected";
            if (message.deviceType != null && message.hasOwnProperty("deviceType"))
                if (!$util.isString(message.deviceType))
                    return "deviceType: string expected";
            if (message.operatingSystem != null && message.hasOwnProperty("operatingSystem"))
                if (!$util.isString(message.operatingSystem))
                    return "operatingSystem: string expected";
            if (message.appName != null && message.hasOwnProperty("appName"))
                if (!$util.isString(message.appName))
                    return "appName: string expected";
            if (message.latitude != null && message.hasOwnProperty("latitude"))
                if (typeof message.latitude !== "number")
                    return "latitude: number expected";
            if (message.longitude != null && message.hasOwnProperty("longitude"))
                if (typeof message.longitude !== "number")
                    return "longitude: number expected";
            if (message.imei != null && message.hasOwnProperty("imei"))
                if (!$util.isString(message.imei))
                    return "imei: string expected";
            if (message.androidId != null && message.hasOwnProperty("androidId"))
                if (!$util.isString(message.androidId))
                    return "androidId: string expected";
            if (message.oaid != null && message.hasOwnProperty("oaid"))
                if (!$util.isString(message.oaid))
                    return "oaid: string expected";
            if (message.googleAdvertisingId != null && message.hasOwnProperty("googleAdvertisingId"))
                if (!$util.isString(message.googleAdvertisingId))
                    return "googleAdvertisingId: string expected";
            if (message.idfa != null && message.hasOwnProperty("idfa"))
                if (!$util.isString(message.idfa))
                    return "idfa: string expected";
            if (message.idfv != null && message.hasOwnProperty("idfv"))
                if (!$util.isString(message.idfv))
                    return "idfv: string expected";
            if (message.orientation != null && message.hasOwnProperty("orientation"))
                if (!$util.isString(message.orientation))
                    return "orientation: string expected";
            if (message.projectKey != null && message.hasOwnProperty("projectKey"))
                if (!$util.isString(message.projectKey))
                    return "projectKey: string expected";
            if (message.sendTime != null && message.hasOwnProperty("sendTime"))
                if (!$util.isInteger(message.sendTime) && !(message.sendTime && $util.isInteger(message.sendTime.low) && $util.isInteger(message.sendTime.high)))
                    return "sendTime: integer|Long expected";
            if (message.userKey != null && message.hasOwnProperty("userKey"))
                if (!$util.isString(message.userKey))
                    return "userKey: string expected";
            if (message.xcontent != null && message.hasOwnProperty("xcontent"))
                if (!$util.isString(message.xcontent))
                    return "xcontent: string expected";
            if (message.timezoneOffset != null && message.hasOwnProperty("timezoneOffset"))
                if (!$util.isString(message.timezoneOffset))
                    return "timezoneOffset: string expected";
            return null;
        };

        /**
         * Creates an EventV3Dto message from a plain object. Also converts values to their respective internal types.
         * @function fromObject
         * @memberof event_pb.EventV3Dto
         * @static
         * @param {Object.<string,*>} object Plain object
         * @returns {event_pb.EventV3Dto} EventV3Dto
         */
        EventV3Dto.fromObject = function fromObject(object) {
            if (object instanceof $root.event_pb.EventV3Dto)
                return object;
            let message = new $root.event_pb.EventV3Dto();
            if (object.deviceId != null)
                message.deviceId = String(object.deviceId);
            if (object.userId != null)
                message.userId = String(object.userId);
            if (object.gioId != null)
                message.gioId = String(object.gioId);
            if (object.sessionId != null)
                message.sessionId = String(object.sessionId);
            if (object.dataSourceId != null)
                message.dataSourceId = String(object.dataSourceId);
            switch (object.eventType) {
            default:
                if (typeof object.eventType === "number") {
                    message.eventType = object.eventType;
                    break;
                }
                break;
            case "VISIT":
            case 0:
                message.eventType = 0;
                break;
            case "CUSTOM":
            case 1:
                message.eventType = 1;
                break;
            case "VISITOR_ATTRIBUTES":
            case 2:
                message.eventType = 2;
                break;
            case "LOGIN_USER_ATTRIBUTES":
            case 3:
                message.eventType = 3;
                break;
            case "CONVERSION_VARIABLES":
            case 4:
                message.eventType = 4;
                break;
            case "APP_CLOSED":
            case 5:
                message.eventType = 5;
                break;
            case "PAGE":
            case 6:
                message.eventType = 6;
                break;
            case "PAGE_ATTRIBUTES":
            case 7:
                message.eventType = 7;
                break;
            case "VIEW_CLICK":
            case 8:
                message.eventType = 8;
                break;
            case "VIEW_CHANGE":
            case 9:
                message.eventType = 9;
                break;
            case "FORM_SUBMIT":
            case 10:
                message.eventType = 10;
                break;
            case "ACTIVATE":
            case 11:
                message.eventType = 11;
                break;
            }
            if (object.platform != null)
                message.platform = String(object.platform);
            if (object.timestamp != null)
                if ($util.Long)
                    (message.timestamp = $util.Long.fromValue(object.timestamp)).unsigned = false;
                else if (typeof object.timestamp === "string")
                    message.timestamp = parseInt(object.timestamp, 10);
                else if (typeof object.timestamp === "number")
                    message.timestamp = object.timestamp;
                else if (typeof object.timestamp === "object")
                    message.timestamp = new $util.LongBits(object.timestamp.low >>> 0, object.timestamp.high >>> 0).toNumber();
            if (object.domain != null)
                message.domain = String(object.domain);
            if (object.path != null)
                message.path = String(object.path);
            if (object.query != null)
                message.query = String(object.query);
            if (object.title != null)
                message.title = String(object.title);
            if (object.referralPage != null)
                message.referralPage = String(object.referralPage);
            if (object.globalSequenceId != null)
                if ($util.Long)
                    (message.globalSequenceId = $util.Long.fromValue(object.globalSequenceId)).unsigned = false;
                else if (typeof object.globalSequenceId === "string")
                    message.globalSequenceId = parseInt(object.globalSequenceId, 10);
                else if (typeof object.globalSequenceId === "number")
                    message.globalSequenceId = object.globalSequenceId;
                else if (typeof object.globalSequenceId === "object")
                    message.globalSequenceId = new $util.LongBits(object.globalSequenceId.low >>> 0, object.globalSequenceId.high >>> 0).toNumber();
            if (object.eventSequenceId != null)
                message.eventSequenceId = object.eventSequenceId | 0;
            if (object.screenHeight != null)
                message.screenHeight = object.screenHeight | 0;
            if (object.screenWidth != null)
                message.screenWidth = object.screenWidth | 0;
            if (object.language != null)
                message.language = String(object.language);
            if (object.sdkVersion != null)
                message.sdkVersion = String(object.sdkVersion);
            if (object.appVersion != null)
                message.appVersion = String(object.appVersion);
            if (object.extraSdk) {
                if (typeof object.extraSdk !== "object")
                    throw TypeError(".event_pb.EventV3Dto.extraSdk: object expected");
                message.extraSdk = {};
                for (let keys = Object.keys(object.extraSdk), i = 0; i < keys.length; ++i)
                    message.extraSdk[keys[i]] = String(object.extraSdk[keys[i]]);
            }
            if (object.eventName != null)
                message.eventName = String(object.eventName);
            if (object.attributes) {
                if (typeof object.attributes !== "object")
                    throw TypeError(".event_pb.EventV3Dto.attributes: object expected");
                message.attributes = {};
                for (let keys = Object.keys(object.attributes), i = 0; i < keys.length; ++i)
                    message.attributes[keys[i]] = String(object.attributes[keys[i]]);
            }
            if (object.resourceItem != null) {
                if (typeof object.resourceItem !== "object")
                    throw TypeError(".event_pb.EventV3Dto.resourceItem: object expected");
                message.resourceItem = $root.event_pb.ResourceItem.fromObject(object.resourceItem);
            }
            if (object.protocolType != null)
                message.protocolType = String(object.protocolType);
            if (object.textValue != null)
                message.textValue = String(object.textValue);
            if (object.xpath != null)
                message.xpath = String(object.xpath);
            if (object.index != null)
                message.index = object.index | 0;
            if (object.hyperlink != null)
                message.hyperlink = String(object.hyperlink);
            if (object.urlScheme != null)
                message.urlScheme = String(object.urlScheme);
            if (object.appState != null)
                message.appState = String(object.appState);
            if (object.networkState != null)
                message.networkState = String(object.networkState);
            if (object.appChannel != null)
                message.appChannel = String(object.appChannel);
            if (object.pageName != null)
                message.pageName = String(object.pageName);
            if (object.platformVersion != null)
                message.platformVersion = String(object.platformVersion);
            if (object.deviceBrand != null)
                message.deviceBrand = String(object.deviceBrand);
            if (object.deviceModel != null)
                message.deviceModel = String(object.deviceModel);
            if (object.deviceType != null)
                message.deviceType = String(object.deviceType);
            if (object.operatingSystem != null)
                message.operatingSystem = String(object.operatingSystem);
            if (object.appName != null)
                message.appName = String(object.appName);
            if (object.latitude != null)
                message.latitude = Number(object.latitude);
            if (object.longitude != null)
                message.longitude = Number(object.longitude);
            if (object.imei != null)
                message.imei = String(object.imei);
            if (object.androidId != null)
                message.androidId = String(object.androidId);
            if (object.oaid != null)
                message.oaid = String(object.oaid);
            if (object.googleAdvertisingId != null)
                message.googleAdvertisingId = String(object.googleAdvertisingId);
            if (object.idfa != null)
                message.idfa = String(object.idfa);
            if (object.idfv != null)
                message.idfv = String(object.idfv);
            if (object.orientation != null)
                message.orientation = String(object.orientation);
            if (object.projectKey != null)
                message.projectKey = String(object.projectKey);
            if (object.sendTime != null)
                if ($util.Long)
                    (message.sendTime = $util.Long.fromValue(object.sendTime)).unsigned = false;
                else if (typeof object.sendTime === "string")
                    message.sendTime = parseInt(object.sendTime, 10);
                else if (typeof object.sendTime === "number")
                    message.sendTime = object.sendTime;
                else if (typeof object.sendTime === "object")
                    message.sendTime = new $util.LongBits(object.sendTime.low >>> 0, object.sendTime.high >>> 0).toNumber();
            if (object.userKey != null)
                message.userKey = String(object.userKey);
            if (object.xcontent != null)
                message.xcontent = String(object.xcontent);
            if (object.timezoneOffset != null)
                message.timezoneOffset = String(object.timezoneOffset);
            return message;
        };

        /**
         * Creates a plain object from an EventV3Dto message. Also converts values to other types if specified.
         * @function toObject
         * @memberof event_pb.EventV3Dto
         * @static
         * @param {event_pb.EventV3Dto} message EventV3Dto
         * @param {$protobuf.IConversionOptions} [options] Conversion options
         * @returns {Object.<string,*>} Plain object
         */
        EventV3Dto.toObject = function toObject(message, options) {
            if (!options)
                options = {};
            let object = {};
            if (options.objects || options.defaults) {
                object.extraSdk = {};
                object.attributes = {};
            }
            if (options.defaults) {
                object.deviceId = "";
                object.userId = "";
                object.gioId = "";
                object.sessionId = "";
                object.dataSourceId = "";
                object.eventType = options.enums === String ? "VISIT" : 0;
                object.platform = "";
                if ($util.Long) {
                    let long = new $util.Long(0, 0, false);
                    object.timestamp = options.longs === String ? long.toString() : options.longs === Number ? long.toNumber() : long;
                } else
                    object.timestamp = options.longs === String ? "0" : 0;
                object.domain = "";
                object.path = "";
                object.query = "";
                object.title = "";
                object.referralPage = "";
                if ($util.Long) {
                    let long = new $util.Long(0, 0, false);
                    object.globalSequenceId = options.longs === String ? long.toString() : options.longs === Number ? long.toNumber() : long;
                } else
                    object.globalSequenceId = options.longs === String ? "0" : 0;
                object.eventSequenceId = 0;
                object.screenHeight = 0;
                object.screenWidth = 0;
                object.language = "";
                object.sdkVersion = "";
                object.appVersion = "";
                object.eventName = "";
                object.resourceItem = null;
                object.protocolType = "";
                object.textValue = "";
                object.xpath = "";
                object.index = 0;
                object.hyperlink = "";
                object.urlScheme = "";
                object.appState = "";
                object.networkState = "";
                object.appChannel = "";
                object.pageName = "";
                object.platformVersion = "";
                object.deviceBrand = "";
                object.deviceModel = "";
                object.deviceType = "";
                object.operatingSystem = "";
                object.appName = "";
                object.latitude = 0;
                object.longitude = 0;
                object.imei = "";
                object.androidId = "";
                object.oaid = "";
                object.googleAdvertisingId = "";
                object.idfa = "";
                object.idfv = "";
                object.orientation = "";
                object.projectKey = "";
                if ($util.Long) {
                    let long = new $util.Long(0, 0, false);
                    object.sendTime = options.longs === String ? long.toString() : options.longs === Number ? long.toNumber() : long;
                } else
                    object.sendTime = options.longs === String ? "0" : 0;
                object.userKey = "";
                object.xcontent = "";
                object.timezoneOffset = "";
            }
            if (message.deviceId != null && message.hasOwnProperty("deviceId"))
                object.deviceId = message.deviceId;
            if (message.userId != null && message.hasOwnProperty("userId"))
                object.userId = message.userId;
            if (message.gioId != null && message.hasOwnProperty("gioId"))
                object.gioId = message.gioId;
            if (message.sessionId != null && message.hasOwnProperty("sessionId"))
                object.sessionId = message.sessionId;
            if (message.dataSourceId != null && message.hasOwnProperty("dataSourceId"))
                object.dataSourceId = message.dataSourceId;
            if (message.eventType != null && message.hasOwnProperty("eventType"))
                object.eventType = options.enums === String ? $root.event_pb.EventType[message.eventType] === undefined ? message.eventType : $root.event_pb.EventType[message.eventType] : message.eventType;
            if (message.platform != null && message.hasOwnProperty("platform"))
                object.platform = message.platform;
            if (message.timestamp != null && message.hasOwnProperty("timestamp"))
                if (typeof message.timestamp === "number")
                    object.timestamp = options.longs === String ? String(message.timestamp) : message.timestamp;
                else
                    object.timestamp = options.longs === String ? $util.Long.prototype.toString.call(message.timestamp) : options.longs === Number ? new $util.LongBits(message.timestamp.low >>> 0, message.timestamp.high >>> 0).toNumber() : message.timestamp;
            if (message.domain != null && message.hasOwnProperty("domain"))
                object.domain = message.domain;
            if (message.path != null && message.hasOwnProperty("path"))
                object.path = message.path;
            if (message.query != null && message.hasOwnProperty("query"))
                object.query = message.query;
            if (message.title != null && message.hasOwnProperty("title"))
                object.title = message.title;
            if (message.referralPage != null && message.hasOwnProperty("referralPage"))
                object.referralPage = message.referralPage;
            if (message.globalSequenceId != null && message.hasOwnProperty("globalSequenceId"))
                if (typeof message.globalSequenceId === "number")
                    object.globalSequenceId = options.longs === String ? String(message.globalSequenceId) : message.globalSequenceId;
                else
                    object.globalSequenceId = options.longs === String ? $util.Long.prototype.toString.call(message.globalSequenceId) : options.longs === Number ? new $util.LongBits(message.globalSequenceId.low >>> 0, message.globalSequenceId.high >>> 0).toNumber() : message.globalSequenceId;
            if (message.eventSequenceId != null && message.hasOwnProperty("eventSequenceId"))
                object.eventSequenceId = message.eventSequenceId;
            if (message.screenHeight != null && message.hasOwnProperty("screenHeight"))
                object.screenHeight = message.screenHeight;
            if (message.screenWidth != null && message.hasOwnProperty("screenWidth"))
                object.screenWidth = message.screenWidth;
            if (message.language != null && message.hasOwnProperty("language"))
                object.language = message.language;
            if (message.sdkVersion != null && message.hasOwnProperty("sdkVersion"))
                object.sdkVersion = message.sdkVersion;
            if (message.appVersion != null && message.hasOwnProperty("appVersion"))
                object.appVersion = message.appVersion;
            let keys2;
            if (message.extraSdk && (keys2 = Object.keys(message.extraSdk)).length) {
                object.extraSdk = {};
                for (let j = 0; j < keys2.length; ++j)
                    object.extraSdk[keys2[j]] = message.extraSdk[keys2[j]];
            }
            if (message.eventName != null && message.hasOwnProperty("eventName"))
                object.eventName = message.eventName;
            if (message.attributes && (keys2 = Object.keys(message.attributes)).length) {
                object.attributes = {};
                for (let j = 0; j < keys2.length; ++j)
                    object.attributes[keys2[j]] = message.attributes[keys2[j]];
            }
            if (message.resourceItem != null && message.hasOwnProperty("resourceItem"))
                object.resourceItem = $root.event_pb.ResourceItem.toObject(message.resourceItem, options);
            if (message.protocolType != null && message.hasOwnProperty("protocolType"))
                object.protocolType = message.protocolType;
            if (message.textValue != null && message.hasOwnProperty("textValue"))
                object.textValue = message.textValue;
            if (message.xpath != null && message.hasOwnProperty("xpath"))
                object.xpath = message.xpath;
            if (message.index != null && message.hasOwnProperty("index"))
                object.index = message.index;
            if (message.hyperlink != null && message.hasOwnProperty("hyperlink"))
                object.hyperlink = message.hyperlink;
            if (message.urlScheme != null && message.hasOwnProperty("urlScheme"))
                object.urlScheme = message.urlScheme;
            if (message.appState != null && message.hasOwnProperty("appState"))
                object.appState = message.appState;
            if (message.networkState != null && message.hasOwnProperty("networkState"))
                object.networkState = message.networkState;
            if (message.appChannel != null && message.hasOwnProperty("appChannel"))
                object.appChannel = message.appChannel;
            if (message.pageName != null && message.hasOwnProperty("pageName"))
                object.pageName = message.pageName;
            if (message.platformVersion != null && message.hasOwnProperty("platformVersion"))
                object.platformVersion = message.platformVersion;
            if (message.deviceBrand != null && message.hasOwnProperty("deviceBrand"))
                object.deviceBrand = message.deviceBrand;
            if (message.deviceModel != null && message.hasOwnProperty("deviceModel"))
                object.deviceModel = message.deviceModel;
            if (message.deviceType != null && message.hasOwnProperty("deviceType"))
                object.deviceType = message.deviceType;
            if (message.operatingSystem != null && message.hasOwnProperty("operatingSystem"))
                object.operatingSystem = message.operatingSystem;
            if (message.appName != null && message.hasOwnProperty("appName"))
                object.appName = message.appName;
            if (message.latitude != null && message.hasOwnProperty("latitude"))
                object.latitude = options.json && !isFinite(message.latitude) ? String(message.latitude) : message.latitude;
            if (message.longitude != null && message.hasOwnProperty("longitude"))
                object.longitude = options.json && !isFinite(message.longitude) ? String(message.longitude) : message.longitude;
            if (message.imei != null && message.hasOwnProperty("imei"))
                object.imei = message.imei;
            if (message.androidId != null && message.hasOwnProperty("androidId"))
                object.androidId = message.androidId;
            if (message.oaid != null && message.hasOwnProperty("oaid"))
                object.oaid = message.oaid;
            if (message.googleAdvertisingId != null && message.hasOwnProperty("googleAdvertisingId"))
                object.googleAdvertisingId = message.googleAdvertisingId;
            if (message.idfa != null && message.hasOwnProperty("idfa"))
                object.idfa = message.idfa;
            if (message.idfv != null && message.hasOwnProperty("idfv"))
                object.idfv = message.idfv;
            if (message.orientation != null && message.hasOwnProperty("orientation"))
                object.orientation = message.orientation;
            if (message.projectKey != null && message.hasOwnProperty("projectKey"))
                object.projectKey = message.projectKey;
            if (message.sendTime != null && message.hasOwnProperty("sendTime"))
                if (typeof message.sendTime === "number")
                    object.sendTime = options.longs === String ? String(message.sendTime) : message.sendTime;
                else
                    object.sendTime = options.longs === String ? $util.Long.prototype.toString.call(message.sendTime) : options.longs === Number ? new $util.LongBits(message.sendTime.low >>> 0, message.sendTime.high >>> 0).toNumber() : message.sendTime;
            if (message.userKey != null && message.hasOwnProperty("userKey"))
                object.userKey = message.userKey;
            if (message.xcontent != null && message.hasOwnProperty("xcontent"))
                object.xcontent = message.xcontent;
            if (message.timezoneOffset != null && message.hasOwnProperty("timezoneOffset"))
                object.timezoneOffset = message.timezoneOffset;
            return object;
        };

        /**
         * Converts this EventV3Dto to JSON.
         * @function toJSON
         * @memberof event_pb.EventV3Dto
         * @instance
         * @returns {Object.<string,*>} JSON object
         */
        EventV3Dto.prototype.toJSON = function toJSON() {
            return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
        };

        /**
         * Gets the default type url for EventV3Dto
         * @function getTypeUrl
         * @memberof event_pb.EventV3Dto
         * @static
         * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
         * @returns {string} The default type url
         */
        EventV3Dto.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
            if (typeUrlPrefix === undefined) {
                typeUrlPrefix = "type.googleapis.com";
            }
            return typeUrlPrefix + "/event_pb.EventV3Dto";
        };

        return EventV3Dto;
    })();

    event_pb.ResourceItem = (function() {

        /**
         * Properties of a ResourceItem.
         * @memberof event_pb
         * @interface IResourceItem
         * @property {string|null} [id] ResourceItem id
         * @property {string|null} [key] ResourceItem key
         * @property {Object.<string,string>|null} [attributes] ResourceItem attributes
         */

        /**
         * Constructs a new ResourceItem.
         * @memberof event_pb
         * @classdesc Represents a ResourceItem.
         * @implements IResourceItem
         * @constructor
         * @param {event_pb.IResourceItem=} [properties] Properties to set
         */
        function ResourceItem(properties) {
            this.attributes = {};
            if (properties)
                for (let keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                    if (properties[keys[i]] != null)
                        this[keys[i]] = properties[keys[i]];
        }

        /**
         * ResourceItem id.
         * @member {string} id
         * @memberof event_pb.ResourceItem
         * @instance
         */
        ResourceItem.prototype.id = "";

        /**
         * ResourceItem key.
         * @member {string} key
         * @memberof event_pb.ResourceItem
         * @instance
         */
        ResourceItem.prototype.key = "";

        /**
         * ResourceItem attributes.
         * @member {Object.<string,string>} attributes
         * @memberof event_pb.ResourceItem
         * @instance
         */
        ResourceItem.prototype.attributes = $util.emptyObject;

        /**
         * Creates a new ResourceItem instance using the specified properties.
         * @function create
         * @memberof event_pb.ResourceItem
         * @static
         * @param {event_pb.IResourceItem=} [properties] Properties to set
         * @returns {event_pb.ResourceItem} ResourceItem instance
         */
        ResourceItem.create = function create(properties) {
            return new ResourceItem(properties);
        };

        /**
         * Encodes the specified ResourceItem message. Does not implicitly {@link event_pb.ResourceItem.verify|verify} messages.
         * @function encode
         * @memberof event_pb.ResourceItem
         * @static
         * @param {event_pb.IResourceItem} message ResourceItem message or plain object to encode
         * @param {$protobuf.Writer} [writer] Writer to encode to
         * @returns {$protobuf.Writer} Writer
         */
        ResourceItem.encode = function encode(message, writer) {
            if (!writer)
                writer = $Writer.create();
            if (message.id != null && Object.hasOwnProperty.call(message, "id"))
                writer.uint32(/* id 1, wireType 2 =*/10).string(message.id);
            if (message.key != null && Object.hasOwnProperty.call(message, "key"))
                writer.uint32(/* id 2, wireType 2 =*/18).string(message.key);
            if (message.attributes != null && Object.hasOwnProperty.call(message, "attributes"))
                for (let keys = Object.keys(message.attributes), i = 0; i < keys.length; ++i)
                    writer.uint32(/* id 3, wireType 2 =*/26).fork().uint32(/* id 1, wireType 2 =*/10).string(keys[i]).uint32(/* id 2, wireType 2 =*/18).string(message.attributes[keys[i]]).ldelim();
            return writer;
        };

        /**
         * Encodes the specified ResourceItem message, length delimited. Does not implicitly {@link event_pb.ResourceItem.verify|verify} messages.
         * @function encodeDelimited
         * @memberof event_pb.ResourceItem
         * @static
         * @param {event_pb.IResourceItem} message ResourceItem message or plain object to encode
         * @param {$protobuf.Writer} [writer] Writer to encode to
         * @returns {$protobuf.Writer} Writer
         */
        ResourceItem.encodeDelimited = function encodeDelimited(message, writer) {
            return this.encode(message, writer).ldelim();
        };

        /**
         * Decodes a ResourceItem message from the specified reader or buffer.
         * @function decode
         * @memberof event_pb.ResourceItem
         * @static
         * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
         * @param {number} [length] Message length if known beforehand
         * @returns {event_pb.ResourceItem} ResourceItem
         * @throws {Error} If the payload is not a reader or valid buffer
         * @throws {$protobuf.util.ProtocolError} If required fields are missing
         */
        ResourceItem.decode = function decode(reader, length) {
            if (!(reader instanceof $Reader))
                reader = $Reader.create(reader);
            let end = length === undefined ? reader.len : reader.pos + length, message = new $root.event_pb.ResourceItem(), key, value;
            while (reader.pos < end) {
                let tag = reader.uint32();
                switch (tag >>> 3) {
                case 1: {
                        message.id = reader.string();
                        break;
                    }
                case 2: {
                        message.key = reader.string();
                        break;
                    }
                case 3: {
                        if (message.attributes === $util.emptyObject)
                            message.attributes = {};
                        let end2 = reader.uint32() + reader.pos;
                        key = "";
                        value = "";
                        while (reader.pos < end2) {
                            let tag2 = reader.uint32();
                            switch (tag2 >>> 3) {
                            case 1:
                                key = reader.string();
                                break;
                            case 2:
                                value = reader.string();
                                break;
                            default:
                                reader.skipType(tag2 & 7);
                                break;
                            }
                        }
                        message.attributes[key] = value;
                        break;
                    }
                default:
                    reader.skipType(tag & 7);
                    break;
                }
            }
            return message;
        };

        /**
         * Decodes a ResourceItem message from the specified reader or buffer, length delimited.
         * @function decodeDelimited
         * @memberof event_pb.ResourceItem
         * @static
         * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
         * @returns {event_pb.ResourceItem} ResourceItem
         * @throws {Error} If the payload is not a reader or valid buffer
         * @throws {$protobuf.util.ProtocolError} If required fields are missing
         */
        ResourceItem.decodeDelimited = function decodeDelimited(reader) {
            if (!(reader instanceof $Reader))
                reader = new $Reader(reader);
            return this.decode(reader, reader.uint32());
        };

        /**
         * Verifies a ResourceItem message.
         * @function verify
         * @memberof event_pb.ResourceItem
         * @static
         * @param {Object.<string,*>} message Plain object to verify
         * @returns {string|null} `null` if valid, otherwise the reason why it is not
         */
        ResourceItem.verify = function verify(message) {
            if (typeof message !== "object" || message === null)
                return "object expected";
            if (message.id != null && message.hasOwnProperty("id"))
                if (!$util.isString(message.id))
                    return "id: string expected";
            if (message.key != null && message.hasOwnProperty("key"))
                if (!$util.isString(message.key))
                    return "key: string expected";
            if (message.attributes != null && message.hasOwnProperty("attributes")) {
                if (!$util.isObject(message.attributes))
                    return "attributes: object expected";
                let key = Object.keys(message.attributes);
                for (let i = 0; i < key.length; ++i)
                    if (!$util.isString(message.attributes[key[i]]))
                        return "attributes: string{k:string} expected";
            }
            return null;
        };

        /**
         * Creates a ResourceItem message from a plain object. Also converts values to their respective internal types.
         * @function fromObject
         * @memberof event_pb.ResourceItem
         * @static
         * @param {Object.<string,*>} object Plain object
         * @returns {event_pb.ResourceItem} ResourceItem
         */
        ResourceItem.fromObject = function fromObject(object) {
            if (object instanceof $root.event_pb.ResourceItem)
                return object;
            let message = new $root.event_pb.ResourceItem();
            if (object.id != null)
                message.id = String(object.id);
            if (object.key != null)
                message.key = String(object.key);
            if (object.attributes) {
                if (typeof object.attributes !== "object")
                    throw TypeError(".event_pb.ResourceItem.attributes: object expected");
                message.attributes = {};
                for (let keys = Object.keys(object.attributes), i = 0; i < keys.length; ++i)
                    message.attributes[keys[i]] = String(object.attributes[keys[i]]);
            }
            return message;
        };

        /**
         * Creates a plain object from a ResourceItem message. Also converts values to other types if specified.
         * @function toObject
         * @memberof event_pb.ResourceItem
         * @static
         * @param {event_pb.ResourceItem} message ResourceItem
         * @param {$protobuf.IConversionOptions} [options] Conversion options
         * @returns {Object.<string,*>} Plain object
         */
        ResourceItem.toObject = function toObject(message, options) {
            if (!options)
                options = {};
            let object = {};
            if (options.objects || options.defaults)
                object.attributes = {};
            if (options.defaults) {
                object.id = "";
                object.key = "";
            }
            if (message.id != null && message.hasOwnProperty("id"))
                object.id = message.id;
            if (message.key != null && message.hasOwnProperty("key"))
                object.key = message.key;
            let keys2;
            if (message.attributes && (keys2 = Object.keys(message.attributes)).length) {
                object.attributes = {};
                for (let j = 0; j < keys2.length; ++j)
                    object.attributes[keys2[j]] = message.attributes[keys2[j]];
            }
            return object;
        };

        /**
         * Converts this ResourceItem to JSON.
         * @function toJSON
         * @memberof event_pb.ResourceItem
         * @instance
         * @returns {Object.<string,*>} JSON object
         */
        ResourceItem.prototype.toJSON = function toJSON() {
            return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
        };

        /**
         * Gets the default type url for ResourceItem
         * @function getTypeUrl
         * @memberof event_pb.ResourceItem
         * @static
         * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
         * @returns {string} The default type url
         */
        ResourceItem.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
            if (typeUrlPrefix === undefined) {
                typeUrlPrefix = "type.googleapis.com";
            }
            return typeUrlPrefix + "/event_pb.ResourceItem";
        };

        return ResourceItem;
    })();

    event_pb.EventV3List = (function() {

        /**
         * Properties of an EventV3List.
         * @memberof event_pb
         * @interface IEventV3List
         * @property {Array.<event_pb.IEventV3Dto>|null} [values] EventV3List values
         */

        /**
         * Constructs a new EventV3List.
         * @memberof event_pb
         * @classdesc Represents an EventV3List.
         * @implements IEventV3List
         * @constructor
         * @param {event_pb.IEventV3List=} [properties] Properties to set
         */
        function EventV3List(properties) {
            this.values = [];
            if (properties)
                for (let keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                    if (properties[keys[i]] != null)
                        this[keys[i]] = properties[keys[i]];
        }

        /**
         * EventV3List values.
         * @member {Array.<event_pb.IEventV3Dto>} values
         * @memberof event_pb.EventV3List
         * @instance
         */
        EventV3List.prototype.values = $util.emptyArray;

        /**
         * Creates a new EventV3List instance using the specified properties.
         * @function create
         * @memberof event_pb.EventV3List
         * @static
         * @param {event_pb.IEventV3List=} [properties] Properties to set
         * @returns {event_pb.EventV3List} EventV3List instance
         */
        EventV3List.create = function create(properties) {
            return new EventV3List(properties);
        };

        /**
         * Encodes the specified EventV3List message. Does not implicitly {@link event_pb.EventV3List.verify|verify} messages.
         * @function encode
         * @memberof event_pb.EventV3List
         * @static
         * @param {event_pb.IEventV3List} message EventV3List message or plain object to encode
         * @param {$protobuf.Writer} [writer] Writer to encode to
         * @returns {$protobuf.Writer} Writer
         */
        EventV3List.encode = function encode(message, writer) {
            if (!writer)
                writer = $Writer.create();
            if (message.values != null && message.values.length)
                for (let i = 0; i < message.values.length; ++i)
                    $root.event_pb.EventV3Dto.encode(message.values[i], writer.uint32(/* id 1, wireType 2 =*/10).fork()).ldelim();
            return writer;
        };

        /**
         * Encodes the specified EventV3List message, length delimited. Does not implicitly {@link event_pb.EventV3List.verify|verify} messages.
         * @function encodeDelimited
         * @memberof event_pb.EventV3List
         * @static
         * @param {event_pb.IEventV3List} message EventV3List message or plain object to encode
         * @param {$protobuf.Writer} [writer] Writer to encode to
         * @returns {$protobuf.Writer} Writer
         */
        EventV3List.encodeDelimited = function encodeDelimited(message, writer) {
            return this.encode(message, writer).ldelim();
        };

        /**
         * Decodes an EventV3List message from the specified reader or buffer.
         * @function decode
         * @memberof event_pb.EventV3List
         * @static
         * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
         * @param {number} [length] Message length if known beforehand
         * @returns {event_pb.EventV3List} EventV3List
         * @throws {Error} If the payload is not a reader or valid buffer
         * @throws {$protobuf.util.ProtocolError} If required fields are missing
         */
        EventV3List.decode = function decode(reader, length) {
            if (!(reader instanceof $Reader))
                reader = $Reader.create(reader);
            let end = length === undefined ? reader.len : reader.pos + length, message = new $root.event_pb.EventV3List();
            while (reader.pos < end) {
                let tag = reader.uint32();
                switch (tag >>> 3) {
                case 1: {
                        if (!(message.values && message.values.length))
                            message.values = [];
                        message.values.push($root.event_pb.EventV3Dto.decode(reader, reader.uint32()));
                        break;
                    }
                default:
                    reader.skipType(tag & 7);
                    break;
                }
            }
            return message;
        };

        /**
         * Decodes an EventV3List message from the specified reader or buffer, length delimited.
         * @function decodeDelimited
         * @memberof event_pb.EventV3List
         * @static
         * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
         * @returns {event_pb.EventV3List} EventV3List
         * @throws {Error} If the payload is not a reader or valid buffer
         * @throws {$protobuf.util.ProtocolError} If required fields are missing
         */
        EventV3List.decodeDelimited = function decodeDelimited(reader) {
            if (!(reader instanceof $Reader))
                reader = new $Reader(reader);
            return this.decode(reader, reader.uint32());
        };

        /**
         * Verifies an EventV3List message.
         * @function verify
         * @memberof event_pb.EventV3List
         * @static
         * @param {Object.<string,*>} message Plain object to verify
         * @returns {string|null} `null` if valid, otherwise the reason why it is not
         */
        EventV3List.verify = function verify(message) {
            if (typeof message !== "object" || message === null)
                return "object expected";
            if (message.values != null && message.hasOwnProperty("values")) {
                if (!Array.isArray(message.values))
                    return "values: array expected";
                for (let i = 0; i < message.values.length; ++i) {
                    let error = $root.event_pb.EventV3Dto.verify(message.values[i]);
                    if (error)
                        return "values." + error;
                }
            }
            return null;
        };

        /**
         * Creates an EventV3List message from a plain object. Also converts values to their respective internal types.
         * @function fromObject
         * @memberof event_pb.EventV3List
         * @static
         * @param {Object.<string,*>} object Plain object
         * @returns {event_pb.EventV3List} EventV3List
         */
        EventV3List.fromObject = function fromObject(object) {
            if (object instanceof $root.event_pb.EventV3List)
                return object;
            let message = new $root.event_pb.EventV3List();
            if (object.values) {
                if (!Array.isArray(object.values))
                    throw TypeError(".event_pb.EventV3List.values: array expected");
                message.values = [];
                for (let i = 0; i < object.values.length; ++i) {
                    if (typeof object.values[i] !== "object")
                        throw TypeError(".event_pb.EventV3List.values: object expected");
                    message.values[i] = $root.event_pb.EventV3Dto.fromObject(object.values[i]);
                }
            }
            return message;
        };

        /**
         * Creates a plain object from an EventV3List message. Also converts values to other types if specified.
         * @function toObject
         * @memberof event_pb.EventV3List
         * @static
         * @param {event_pb.EventV3List} message EventV3List
         * @param {$protobuf.IConversionOptions} [options] Conversion options
         * @returns {Object.<string,*>} Plain object
         */
        EventV3List.toObject = function toObject(message, options) {
            if (!options)
                options = {};
            let object = {};
            if (options.arrays || options.defaults)
                object.values = [];
            if (message.values && message.values.length) {
                object.values = [];
                for (let j = 0; j < message.values.length; ++j)
                    object.values[j] = $root.event_pb.EventV3Dto.toObject(message.values[j], options);
            }
            return object;
        };

        /**
         * Converts this EventV3List to JSON.
         * @function toJSON
         * @memberof event_pb.EventV3List
         * @instance
         * @returns {Object.<string,*>} JSON object
         */
        EventV3List.prototype.toJSON = function toJSON() {
            return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
        };

        /**
         * Gets the default type url for EventV3List
         * @function getTypeUrl
         * @memberof event_pb.EventV3List
         * @static
         * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
         * @returns {string} The default type url
         */
        EventV3List.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
            if (typeUrlPrefix === undefined) {
                typeUrlPrefix = "type.googleapis.com";
            }
            return typeUrlPrefix + "/event_pb.EventV3List";
        };

        return EventV3List;
    })();

    /**
     * EventType enum.
     * @name event_pb.EventType
     * @enum {number}
     * @property {number} VISIT=0 VISIT value
     * @property {number} CUSTOM=1 CUSTOM value
     * @property {number} VISITOR_ATTRIBUTES=2 VISITOR_ATTRIBUTES value
     * @property {number} LOGIN_USER_ATTRIBUTES=3 LOGIN_USER_ATTRIBUTES value
     * @property {number} CONVERSION_VARIABLES=4 CONVERSION_VARIABLES value
     * @property {number} APP_CLOSED=5 APP_CLOSED value
     * @property {number} PAGE=6 PAGE value
     * @property {number} PAGE_ATTRIBUTES=7 PAGE_ATTRIBUTES value
     * @property {number} VIEW_CLICK=8 VIEW_CLICK value
     * @property {number} VIEW_CHANGE=9 VIEW_CHANGE value
     * @property {number} FORM_SUBMIT=10 FORM_SUBMIT value
     * @property {number} ACTIVATE=11 ACTIVATE value
     */
    event_pb.EventType = (function() {
        const valuesById = {}, values = Object.create(valuesById);
        values[valuesById[0] = "VISIT"] = 0;
        values[valuesById[1] = "CUSTOM"] = 1;
        values[valuesById[2] = "VISITOR_ATTRIBUTES"] = 2;
        values[valuesById[3] = "LOGIN_USER_ATTRIBUTES"] = 3;
        values[valuesById[4] = "CONVERSION_VARIABLES"] = 4;
        values[valuesById[5] = "APP_CLOSED"] = 5;
        values[valuesById[6] = "PAGE"] = 6;
        values[valuesById[7] = "PAGE_ATTRIBUTES"] = 7;
        values[valuesById[8] = "VIEW_CLICK"] = 8;
        values[valuesById[9] = "VIEW_CHANGE"] = 9;
        values[valuesById[10] = "FORM_SUBMIT"] = 10;
        values[valuesById[11] = "ACTIVATE"] = 11;
        return values;
    })();

    return event_pb;
})();

export { $root as default };
