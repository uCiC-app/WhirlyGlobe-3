/*
 *  BillboardManager.java
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
package com.mousebird.maply;

import java.util.List;


public class BillboardManager {


    public BillboardManager(Scene scene) {
        initialise(scene);
    }

    public native long addBillboards (List<Billboard> billboards, BillboardInfo billboardInfo, long billShader, ChangeSet changes);

    public native void enableBillboards(long [] billIDs, boolean enable, ChangeSet changes);

    public native void removeBillboards(long [] billIDs, ChangeSet changes);
    
    public void finalize()
    {
        dispose();
    }

    static
    {
        nativeInit();
    }
    private static native void nativeInit();
    native void initialise(Scene scene);
    native void dispose();
}
