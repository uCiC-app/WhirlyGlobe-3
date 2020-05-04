/*
 *  MapboxVectorTileParser_Android.h
 *  WhirlyGlobeLib
 *
 *  Created by Steve Gifford on 4/12/19.
 *  Copyright 2011-2019 mousebird consulting
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

#import <jni.h>
#import "WhirlyGlobe.h"
#import "LabelInfo_Android.h"

namespace WhirlyKit
{

/// Used to pass around the JNIEnv per thread
class VectorStyleInst_Android : public VectorStyleInst
{
public:
    JNIEnv *env;
};

/// Android version of the Mapbox Vector Style Set
/// Just implements the platform local stuff
class MapboxVectorStyleSetImpl_Android : public MapboxVectorStyleSetImpl
{
public:
    MapboxVectorStyleSetImpl_Android(Scene *scene,VectorStyleSettingsImplRef settings);
    ~MapboxVectorStyleSetImpl_Android();

    /** Platform specific implementation **/

    /// Local platform implementation for generating a circle and adding it as a texture
    virtual SimpleIdentity makeCircleTexture(VectorStyleInst *inst,
            double radius,
            const RGBAColor &fillColor,
            const RGBAColor &strokeColor,
            float strokeWidth,
            Point2f *circleSize);

    /// Local platform implementation for generating a repeating line texture
    virtual SimpleIdentity makeLineTexture(VectorStyleInst *inst,const std::vector<double> &dashComponents);

    /// Create a local platform LabelInfo (since fonts are local)
    virtual LabelInfoRef makeLabelInfo(VectorStyleInst *inst,const std::string &fontName,float fontSize);

    /// Create a local platform label (fonts are local, and other stuff)
    virtual SingleLabelRef makeSingleLabel(VectorStyleInst *inst,const std::string &text);

    /// Create a local platform component object
    virtual ComponentObjectRef makeComponentObject(VectorStyleInst *inst);

    /// Set up the Java side method references
    void setupMethods(JNIEnv *env);

    /// Clean up any JNI references
    void cleanup(JNIEnv *env);

public:
    jobject thisObj;
    jmethodID makeLabelInfoMethod;
    jmethodID makeCircleTextureMethod;
    jmethodID makeLineTextureMethod;

    // Map fontName/size to Java-side labelInfo objects
    std::map<std::pair<std::string, float>, LabelInfoAndroid *> labelInfos;
};
typedef std::shared_ptr<MapboxVectorStyleSetImpl_Android> MapboxVectorStyleSetImpl_AndroidRef;

}