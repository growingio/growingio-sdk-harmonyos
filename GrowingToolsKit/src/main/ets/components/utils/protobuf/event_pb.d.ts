import * as $protobuf from "@ohos/protobufjs";
import Long = require("long");
/** Namespace event_pb. */
export namespace event_pb {

    /** Properties of an EventV3Dto. */
    interface IEventV3Dto {

        /** EventV3Dto deviceId */
        deviceId?: (string|null);

        /** EventV3Dto userId */
        userId?: (string|null);

        /** EventV3Dto gioId */
        gioId?: (string|null);

        /** EventV3Dto sessionId */
        sessionId?: (string|null);

        /** EventV3Dto dataSourceId */
        dataSourceId?: (string|null);

        /** EventV3Dto eventType */
        eventType?: (event_pb.EventType|null);

        /** EventV3Dto platform */
        platform?: (string|null);

        /** EventV3Dto timestamp */
        timestamp?: (number|Long|null);

        /** EventV3Dto domain */
        domain?: (string|null);

        /** EventV3Dto path */
        path?: (string|null);

        /** EventV3Dto query */
        query?: (string|null);

        /** EventV3Dto title */
        title?: (string|null);

        /** EventV3Dto referralPage */
        referralPage?: (string|null);

        /** EventV3Dto globalSequenceId */
        globalSequenceId?: (number|Long|null);

        /** EventV3Dto eventSequenceId */
        eventSequenceId?: (number|null);

        /** EventV3Dto screenHeight */
        screenHeight?: (number|null);

        /** EventV3Dto screenWidth */
        screenWidth?: (number|null);

        /** EventV3Dto language */
        language?: (string|null);

        /** EventV3Dto sdkVersion */
        sdkVersion?: (string|null);

        /** EventV3Dto appVersion */
        appVersion?: (string|null);

        /** EventV3Dto extraSdk */
        extraSdk?: ({ [k: string]: string }|null);

        /** EventV3Dto eventName */
        eventName?: (string|null);

        /** EventV3Dto attributes */
        attributes?: ({ [k: string]: string }|null);

        /** EventV3Dto resourceItem */
        resourceItem?: (event_pb.IResourceItem|null);

        /** EventV3Dto protocolType */
        protocolType?: (string|null);

        /** EventV3Dto textValue */
        textValue?: (string|null);

        /** EventV3Dto xpath */
        xpath?: (string|null);

        /** EventV3Dto index */
        index?: (number|null);

        /** EventV3Dto hyperlink */
        hyperlink?: (string|null);

        /** EventV3Dto urlScheme */
        urlScheme?: (string|null);

        /** EventV3Dto appState */
        appState?: (string|null);

        /** EventV3Dto networkState */
        networkState?: (string|null);

        /** EventV3Dto appChannel */
        appChannel?: (string|null);

        /** EventV3Dto pageName */
        pageName?: (string|null);

        /** EventV3Dto platformVersion */
        platformVersion?: (string|null);

        /** EventV3Dto deviceBrand */
        deviceBrand?: (string|null);

        /** EventV3Dto deviceModel */
        deviceModel?: (string|null);

        /** EventV3Dto deviceType */
        deviceType?: (string|null);

        /** EventV3Dto operatingSystem */
        operatingSystem?: (string|null);

        /** EventV3Dto appName */
        appName?: (string|null);

        /** EventV3Dto latitude */
        latitude?: (number|null);

        /** EventV3Dto longitude */
        longitude?: (number|null);

        /** EventV3Dto imei */
        imei?: (string|null);

        /** EventV3Dto androidId */
        androidId?: (string|null);

        /** EventV3Dto oaid */
        oaid?: (string|null);

        /** EventV3Dto googleAdvertisingId */
        googleAdvertisingId?: (string|null);

        /** EventV3Dto idfa */
        idfa?: (string|null);

        /** EventV3Dto idfv */
        idfv?: (string|null);

        /** EventV3Dto orientation */
        orientation?: (string|null);

        /** EventV3Dto projectKey */
        projectKey?: (string|null);

        /** EventV3Dto sendTime */
        sendTime?: (number|Long|null);

        /** EventV3Dto userKey */
        userKey?: (string|null);

        /** EventV3Dto xcontent */
        xcontent?: (string|null);

        /** EventV3Dto timezoneOffset */
        timezoneOffset?: (string|null);
    }

    /** Represents an EventV3Dto. */
    class EventV3Dto implements IEventV3Dto {

        /**
         * Constructs a new EventV3Dto.
         * @param [properties] Properties to set
         */
        constructor(properties?: event_pb.IEventV3Dto);

        /** EventV3Dto deviceId. */
        public deviceId: string;

        /** EventV3Dto userId. */
        public userId: string;

        /** EventV3Dto gioId. */
        public gioId: string;

        /** EventV3Dto sessionId. */
        public sessionId: string;

        /** EventV3Dto dataSourceId. */
        public dataSourceId: string;

        /** EventV3Dto eventType. */
        public eventType: event_pb.EventType;

        /** EventV3Dto platform. */
        public platform: string;

        /** EventV3Dto timestamp. */
        public timestamp: (number|Long);

        /** EventV3Dto domain. */
        public domain: string;

        /** EventV3Dto path. */
        public path: string;

        /** EventV3Dto query. */
        public query: string;

        /** EventV3Dto title. */
        public title: string;

        /** EventV3Dto referralPage. */
        public referralPage: string;

        /** EventV3Dto globalSequenceId. */
        public globalSequenceId: (number|Long);

        /** EventV3Dto eventSequenceId. */
        public eventSequenceId: number;

        /** EventV3Dto screenHeight. */
        public screenHeight: number;

        /** EventV3Dto screenWidth. */
        public screenWidth: number;

        /** EventV3Dto language. */
        public language: string;

        /** EventV3Dto sdkVersion. */
        public sdkVersion: string;

        /** EventV3Dto appVersion. */
        public appVersion: string;

        /** EventV3Dto extraSdk. */
        public extraSdk: { [k: string]: string };

        /** EventV3Dto eventName. */
        public eventName: string;

        /** EventV3Dto attributes. */
        public attributes: { [k: string]: string };

        /** EventV3Dto resourceItem. */
        public resourceItem?: (event_pb.IResourceItem|null);

        /** EventV3Dto protocolType. */
        public protocolType: string;

        /** EventV3Dto textValue. */
        public textValue: string;

        /** EventV3Dto xpath. */
        public xpath: string;

        /** EventV3Dto index. */
        public index: number;

        /** EventV3Dto hyperlink. */
        public hyperlink: string;

        /** EventV3Dto urlScheme. */
        public urlScheme: string;

        /** EventV3Dto appState. */
        public appState: string;

        /** EventV3Dto networkState. */
        public networkState: string;

        /** EventV3Dto appChannel. */
        public appChannel: string;

        /** EventV3Dto pageName. */
        public pageName: string;

        /** EventV3Dto platformVersion. */
        public platformVersion: string;

        /** EventV3Dto deviceBrand. */
        public deviceBrand: string;

        /** EventV3Dto deviceModel. */
        public deviceModel: string;

        /** EventV3Dto deviceType. */
        public deviceType: string;

        /** EventV3Dto operatingSystem. */
        public operatingSystem: string;

        /** EventV3Dto appName. */
        public appName: string;

        /** EventV3Dto latitude. */
        public latitude: number;

        /** EventV3Dto longitude. */
        public longitude: number;

        /** EventV3Dto imei. */
        public imei: string;

        /** EventV3Dto androidId. */
        public androidId: string;

        /** EventV3Dto oaid. */
        public oaid: string;

        /** EventV3Dto googleAdvertisingId. */
        public googleAdvertisingId: string;

        /** EventV3Dto idfa. */
        public idfa: string;

        /** EventV3Dto idfv. */
        public idfv: string;

        /** EventV3Dto orientation. */
        public orientation: string;

        /** EventV3Dto projectKey. */
        public projectKey: string;

        /** EventV3Dto sendTime. */
        public sendTime: (number|Long);

        /** EventV3Dto userKey. */
        public userKey: string;

        /** EventV3Dto xcontent. */
        public xcontent: string;

        /** EventV3Dto timezoneOffset. */
        public timezoneOffset: string;

        /**
         * Creates a new EventV3Dto instance using the specified properties.
         * @param [properties] Properties to set
         * @returns EventV3Dto instance
         */
        public static create(properties?: event_pb.IEventV3Dto): event_pb.EventV3Dto;

        /**
         * Encodes the specified EventV3Dto message. Does not implicitly {@link event_pb.EventV3Dto.verify|verify} messages.
         * @param message EventV3Dto message or plain object to encode
         * @param [writer] Writer to encode to
         * @returns Writer
         */
        public static encode(message: event_pb.IEventV3Dto, writer?: $protobuf.Writer): $protobuf.Writer;

        /**
         * Encodes the specified EventV3Dto message, length delimited. Does not implicitly {@link event_pb.EventV3Dto.verify|verify} messages.
         * @param message EventV3Dto message or plain object to encode
         * @param [writer] Writer to encode to
         * @returns Writer
         */
        public static encodeDelimited(message: event_pb.IEventV3Dto, writer?: $protobuf.Writer): $protobuf.Writer;

        /**
         * Decodes an EventV3Dto message from the specified reader or buffer.
         * @param reader Reader or buffer to decode from
         * @param [length] Message length if known beforehand
         * @returns EventV3Dto
         * @throws {Error} If the payload is not a reader or valid buffer
         * @throws {$protobuf.util.ProtocolError} If required fields are missing
         */
        public static decode(reader: ($protobuf.Reader|Uint8Array), length?: number): event_pb.EventV3Dto;

        /**
         * Decodes an EventV3Dto message from the specified reader or buffer, length delimited.
         * @param reader Reader or buffer to decode from
         * @returns EventV3Dto
         * @throws {Error} If the payload is not a reader or valid buffer
         * @throws {$protobuf.util.ProtocolError} If required fields are missing
         */
        public static decodeDelimited(reader: ($protobuf.Reader|Uint8Array)): event_pb.EventV3Dto;

        /**
         * Verifies an EventV3Dto message.
         * @param message Plain object to verify
         * @returns `null` if valid, otherwise the reason why it is not
         */
        public static verify(message: { [k: string]: any }): (string|null);

        /**
         * Creates an EventV3Dto message from a plain object. Also converts values to their respective internal types.
         * @param object Plain object
         * @returns EventV3Dto
         */
        public static fromObject(object: { [k: string]: any }): event_pb.EventV3Dto;

        /**
         * Creates a plain object from an EventV3Dto message. Also converts values to other types if specified.
         * @param message EventV3Dto
         * @param [options] Conversion options
         * @returns Plain object
         */
        public static toObject(message: event_pb.EventV3Dto, options?: $protobuf.IConversionOptions): { [k: string]: any };

        /**
         * Converts this EventV3Dto to JSON.
         * @returns JSON object
         */
        public toJSON(): { [k: string]: any };

        /**
         * Gets the default type url for EventV3Dto
         * @param [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
         * @returns The default type url
         */
        public static getTypeUrl(typeUrlPrefix?: string): string;
    }

    /** Properties of a ResourceItem. */
    interface IResourceItem {

        /** ResourceItem id */
        id?: (string|null);

        /** ResourceItem key */
        key?: (string|null);

        /** ResourceItem attributes */
        attributes?: ({ [k: string]: string }|null);
    }

    /** Represents a ResourceItem. */
    class ResourceItem implements IResourceItem {

        /**
         * Constructs a new ResourceItem.
         * @param [properties] Properties to set
         */
        constructor(properties?: event_pb.IResourceItem);

        /** ResourceItem id. */
        public id: string;

        /** ResourceItem key. */
        public key: string;

        /** ResourceItem attributes. */
        public attributes: { [k: string]: string };

        /**
         * Creates a new ResourceItem instance using the specified properties.
         * @param [properties] Properties to set
         * @returns ResourceItem instance
         */
        public static create(properties?: event_pb.IResourceItem): event_pb.ResourceItem;

        /**
         * Encodes the specified ResourceItem message. Does not implicitly {@link event_pb.ResourceItem.verify|verify} messages.
         * @param message ResourceItem message or plain object to encode
         * @param [writer] Writer to encode to
         * @returns Writer
         */
        public static encode(message: event_pb.IResourceItem, writer?: $protobuf.Writer): $protobuf.Writer;

        /**
         * Encodes the specified ResourceItem message, length delimited. Does not implicitly {@link event_pb.ResourceItem.verify|verify} messages.
         * @param message ResourceItem message or plain object to encode
         * @param [writer] Writer to encode to
         * @returns Writer
         */
        public static encodeDelimited(message: event_pb.IResourceItem, writer?: $protobuf.Writer): $protobuf.Writer;

        /**
         * Decodes a ResourceItem message from the specified reader or buffer.
         * @param reader Reader or buffer to decode from
         * @param [length] Message length if known beforehand
         * @returns ResourceItem
         * @throws {Error} If the payload is not a reader or valid buffer
         * @throws {$protobuf.util.ProtocolError} If required fields are missing
         */
        public static decode(reader: ($protobuf.Reader|Uint8Array), length?: number): event_pb.ResourceItem;

        /**
         * Decodes a ResourceItem message from the specified reader or buffer, length delimited.
         * @param reader Reader or buffer to decode from
         * @returns ResourceItem
         * @throws {Error} If the payload is not a reader or valid buffer
         * @throws {$protobuf.util.ProtocolError} If required fields are missing
         */
        public static decodeDelimited(reader: ($protobuf.Reader|Uint8Array)): event_pb.ResourceItem;

        /**
         * Verifies a ResourceItem message.
         * @param message Plain object to verify
         * @returns `null` if valid, otherwise the reason why it is not
         */
        public static verify(message: { [k: string]: any }): (string|null);

        /**
         * Creates a ResourceItem message from a plain object. Also converts values to their respective internal types.
         * @param object Plain object
         * @returns ResourceItem
         */
        public static fromObject(object: { [k: string]: any }): event_pb.ResourceItem;

        /**
         * Creates a plain object from a ResourceItem message. Also converts values to other types if specified.
         * @param message ResourceItem
         * @param [options] Conversion options
         * @returns Plain object
         */
        public static toObject(message: event_pb.ResourceItem, options?: $protobuf.IConversionOptions): { [k: string]: any };

        /**
         * Converts this ResourceItem to JSON.
         * @returns JSON object
         */
        public toJSON(): { [k: string]: any };

        /**
         * Gets the default type url for ResourceItem
         * @param [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
         * @returns The default type url
         */
        public static getTypeUrl(typeUrlPrefix?: string): string;
    }

    /** Properties of an EventV3List. */
    interface IEventV3List {

        /** EventV3List values */
        values?: (event_pb.IEventV3Dto[]|null);
    }

    /** Represents an EventV3List. */
    class EventV3List implements IEventV3List {

        /**
         * Constructs a new EventV3List.
         * @param [properties] Properties to set
         */
        constructor(properties?: event_pb.IEventV3List);

        /** EventV3List values. */
        public values: event_pb.IEventV3Dto[];

        /**
         * Creates a new EventV3List instance using the specified properties.
         * @param [properties] Properties to set
         * @returns EventV3List instance
         */
        public static create(properties?: event_pb.IEventV3List): event_pb.EventV3List;

        /**
         * Encodes the specified EventV3List message. Does not implicitly {@link event_pb.EventV3List.verify|verify} messages.
         * @param message EventV3List message or plain object to encode
         * @param [writer] Writer to encode to
         * @returns Writer
         */
        public static encode(message: event_pb.IEventV3List, writer?: $protobuf.Writer): $protobuf.Writer;

        /**
         * Encodes the specified EventV3List message, length delimited. Does not implicitly {@link event_pb.EventV3List.verify|verify} messages.
         * @param message EventV3List message or plain object to encode
         * @param [writer] Writer to encode to
         * @returns Writer
         */
        public static encodeDelimited(message: event_pb.IEventV3List, writer?: $protobuf.Writer): $protobuf.Writer;

        /**
         * Decodes an EventV3List message from the specified reader or buffer.
         * @param reader Reader or buffer to decode from
         * @param [length] Message length if known beforehand
         * @returns EventV3List
         * @throws {Error} If the payload is not a reader or valid buffer
         * @throws {$protobuf.util.ProtocolError} If required fields are missing
         */
        public static decode(reader: ($protobuf.Reader|Uint8Array), length?: number): event_pb.EventV3List;

        /**
         * Decodes an EventV3List message from the specified reader or buffer, length delimited.
         * @param reader Reader or buffer to decode from
         * @returns EventV3List
         * @throws {Error} If the payload is not a reader or valid buffer
         * @throws {$protobuf.util.ProtocolError} If required fields are missing
         */
        public static decodeDelimited(reader: ($protobuf.Reader|Uint8Array)): event_pb.EventV3List;

        /**
         * Verifies an EventV3List message.
         * @param message Plain object to verify
         * @returns `null` if valid, otherwise the reason why it is not
         */
        public static verify(message: { [k: string]: any }): (string|null);

        /**
         * Creates an EventV3List message from a plain object. Also converts values to their respective internal types.
         * @param object Plain object
         * @returns EventV3List
         */
        public static fromObject(object: { [k: string]: any }): event_pb.EventV3List;

        /**
         * Creates a plain object from an EventV3List message. Also converts values to other types if specified.
         * @param message EventV3List
         * @param [options] Conversion options
         * @returns Plain object
         */
        public static toObject(message: event_pb.EventV3List, options?: $protobuf.IConversionOptions): { [k: string]: any };

        /**
         * Converts this EventV3List to JSON.
         * @returns JSON object
         */
        public toJSON(): { [k: string]: any };

        /**
         * Gets the default type url for EventV3List
         * @param [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
         * @returns The default type url
         */
        public static getTypeUrl(typeUrlPrefix?: string): string;
    }

    /** EventType enum. */
    enum EventType {
        VISIT = 0,
        CUSTOM = 1,
        VISITOR_ATTRIBUTES = 2,
        LOGIN_USER_ATTRIBUTES = 3,
        CONVERSION_VARIABLES = 4,
        APP_CLOSED = 5,
        PAGE = 6,
        PAGE_ATTRIBUTES = 7,
        VIEW_CLICK = 8,
        VIEW_CHANGE = 9,
        FORM_SUBMIT = 10,
        ACTIVATE = 11
    }
}
