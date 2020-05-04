/*
 *  MapboxVectorStyleSet_jni.cpp
 *  WhirlyGlobeLib
 *
 *  Created by sjg
 *  Copyright 2011-2020 mousebird consulting
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 */

#import <Formats_jni.h>
#import <Scene_jni.h>
#import "com_mousebird_maply_MapboxVectorStyleSet.h"

using namespace WhirlyKit;

template<> MapboxVectorStyleSetClassInfo *MapboxVectorStyleSetClassInfo::classInfoObj = NULL;

JNIEXPORT void JNICALL Java_com_mousebird_maply_MapboxVectorStyleSet_nativeInit
(JNIEnv *env, jclass cls)
{
    MapboxVectorStyleSetClassInfo::getClassInfo(env,cls);
}

JNIEXPORT void JNICALL Java_com_mousebird_maply_MapboxVectorStyleSet_initialise
(JNIEnv *env, jobject obj, jobject sceneObj, jobject settingsObj, jstring inJsonStr)
{
    try
    {
        Scene *scene = SceneClassInfo::getClassInfo()->getObject(env,sceneObj);
        JavaString jsonStr(env,inJsonStr);
        MutableDictionary_AndroidRef jsonDict(new MutableDictionary_Android());
        if (!jsonDict->parseJSON(jsonStr.cStr))
            return;

        // Use settings or provide a default
        VectorStyleSettingsImplRef settings;
        if (settingsObj) {
            settings = *(VectorStyleSettingsClassInfo::getClassInfo()->getObject(env,settingsObj));
        } else
            settings = VectorStyleSettingsImplRef(new VectorStyleSettingsImpl(1.0));
        MapboxVectorStyleSetImpl_AndroidRef *inst = new MapboxVectorStyleSetImpl_AndroidRef(new MapboxVectorStyleSetImpl_Android(scene,settings));

        // Need a pointer to this JNIEnv for low level parsing callbacks
        VectorStyleInst_Android threadInst;
        threadInst.env = env;

        bool success = (*inst)->parse(&threadInst,jsonDict);
        (*inst)->thisObj = env->NewGlobalRef(obj);
        MapboxVectorStyleSetClassInfo::getClassInfo()->setHandle(env,obj,inst);
    }
    catch (...)
    {
        __android_log_print(ANDROID_LOG_VERBOSE, "Maply", "Crash in MapboxVectorStyleSet::initialise()");
    }
}

static std::mutex disposeMutex;

JNIEXPORT void JNICALL Java_com_mousebird_maply_MapboxVectorStyleSet_dispose
(JNIEnv *env, jobject obj)
{
    try
    {
        MapboxVectorStyleSetClassInfo *classInfo = MapboxVectorStyleSetClassInfo::getClassInfo();
        {
            std::lock_guard<std::mutex> lock(disposeMutex);
            MapboxVectorStyleSetImpl_AndroidRef *inst = classInfo->getObject(env,obj);
            if (!inst)
                return;
            (*inst)->cleanup(env);
            env->DeleteGlobalRef((*inst)->thisObj);
            delete inst;
        }

        classInfo->clearHandle(env,obj);
    }
    catch (...)
    {
        __android_log_print(ANDROID_LOG_VERBOSE, "Maply", "Crash in MapboxVectorStyleSet::dispose()");
    }
}
