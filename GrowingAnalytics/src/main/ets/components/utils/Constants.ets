/**
 * @license
 * Copyright (C) 2023 Beijing Yishu Technology Co., Ltd.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

export const PREFERENCE_NAME = 'growing_analytics_sp'
export const PREFERENCE_USER_ID = "growing_user_id"
export const PREFERENCE_USER_KEY = "growing_user_key"
export const PREFERENCE_USER_IDENTIFIER = "growing_user_identifier"
export const PREFERENCE_DEVICE_ID = "growing_device_id"
export const PREFERENCE_EVENT_SEQUENCE_ID = "growing_event_sequence_id"

export const Event_DURATION = "event_duration"

export const SDK_VERSION = "1.0.0"

export type AttributesType = { [key: string]: string | number | boolean | string[] | number[] };