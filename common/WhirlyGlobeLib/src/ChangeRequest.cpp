/*
 *  ChangeRequest.cpp
 *  WhirlyGlobeLib
 *
 *  Created by Steve Gifford on 5/8/19.
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

#import "ChangeRequest.h"

namespace WhirlyKit
{

ChangeRequest::ChangeRequest() : when(0.0) { }

ChangeRequest::~ChangeRequest()
{
}

bool ChangeRequest::needsFlush() { return false; }

void ChangeRequest::setupForRenderer(const RenderSetupInfo *) { }

bool ChangeRequest::needPreExecute() { return false; }

}
