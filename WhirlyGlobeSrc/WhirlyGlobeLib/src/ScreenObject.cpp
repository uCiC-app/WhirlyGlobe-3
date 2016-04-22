/*
 *  ScreenObject.cpp
 *  WhirlyGlobeLib
 *
 *  Created by jmnavarro
 *  Copyright 2011-2016 mousebird consulting
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

#import "ScreenObject.h"

namespace WhirlyKit
{

SimplePoly::SimplePoly() :
    texture(NULL),
    color(new RGBAColor())
{
}

SimplePoly::~SimplePoly()
{

}

StringWrapper::StringWrapper() :
    mat(Matrix3d()),
    size(CGSize(0,0))
{
}

ScreenObject::ScreenObject()
{
}

ScreenObject::~ScreenObject()
{
}

}
