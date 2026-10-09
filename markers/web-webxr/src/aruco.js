import aruco from 'js-aruco2';
import 'js-aruco2/src/dictionaries/aruco_4x4_1000.js';
import {squareObservation} from './geometry.js';
const {AR}=aruco;
AR.DICTIONARIES.DICT_4X4_50={...AR.DICTIONARIES.ARUCO_4X4_1000,codeList:AR.DICTIONARIES.ARUCO_4X4_1000.codeList.slice(0,50),tau:4};
export class ArucoTracker{constructor(contract){this.contract=contract;this.detector=new AR.Detector({dictionaryName:'DICT_4X4_50',maxHammingDistance:0})}detect(image){return this.detector.detect(image).filter(m=>this.contract.aruco.ids.includes(m.id)).map(m=>({id:m.id,tracker:'aruco-DICT_4X4_50',...squareObservation(m.corners,this.contract.aruco.blackSquareSizeM),decodedCorners:4,fitResidualPx:null}))}}
