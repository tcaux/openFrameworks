#include "ofxBaseGroup.h"
#include "ofxPanel.h"

ofxBaseGroup::ofxBaseGroup(string collectionName, string filename, float x, float y){
    this->setup(collectionName, filename, x, y);
}

ofxBaseGroup::ofxBaseGroup(const ofParameterGroup & parameters, string filename, float x, float y){
    this->setup(parameters, filename, x, y);
}

ofxBaseGroup * ofxBaseGroup::setup(string collectionName, string filename, float x, float y){
	name = collectionName;
	this->parameters.setName(name);
	b.x = x;
	b.y = y;
	header = defaultHeight;
	spacing  = 1;
	b.width = defaultWidth;
    this->clear();
	this->filename = filename;
    
	ofRegisterMouseEvents(this);
    
	return this;
}


ofxBaseGroup * ofxBaseGroup::setup(const ofParameterGroup & parameters, string filename, float x, float y){
	name = parameters.getName();
	this->parameters.setName(name);
	b.x = x;
	b.y = y;
	header = defaultHeight;
	spacing  = 1;
	b.width = defaultWidth;
    this->clear();
	this->filename = filename;
    
    this->add(parameters);
    
	ofRegisterMouseEvents(this);
    
	return this;
}

void ofxBaseGroup::add(ofxBaseGui * element){
	collection.push_back( element );
    
	element->setPosition(0, b.height);
    
	b.height += element->getHeight() + spacing;
	if(b.width<element->getWidth()) b.width = element->getWidth();
    
	ofUnregisterMouseEvents(element);
    
	ofxPanel * subpanel = dynamic_cast<ofxPanel*>(element);
	if(subpanel!=NULL){
		subpanel->filename = filename;
	}
    
	parameters.add(element->getParameter());
}

void ofxBaseGroup::add(const ofParameterGroup & parameters){
    for(int i=0;i<parameters.size();i++){
		string type = parameters.getType(i);
		if(type==typeid(ofParameter<int>).name()){
			ofParameter<int> p = parameters.getInt(i);
			add(p);
		}else if(type==typeid(ofParameter<float>).name()){
			ofParameter<float> p = parameters.getFloat(i);
			add(p);
		}else if(type==typeid(ofParameter<bool>).name()){
			ofParameter<bool> p = parameters.getBool(i);
			add(p);
		}else if(type==typeid(ofParameterGroup).name()){
			ofParameterGroup p = parameters.getGroup(i);
			ofxPanel * panel = new ofxPanel(p);
			add(panel);
		}else{
			ofLogError() << "ofxPanel; can't add control of type " << type;
		}
	}

}

void ofxBaseGroup::add(ofParameter<float> & parameter){
	add(new ofxFloatSlider(parameter.getName(),parameter,parameter.getMin(),parameter.getMax()));
}

void ofxBaseGroup::add(ofParameter<int> & parameter){
	add(new ofxIntSlider(parameter.getName(),parameter,parameter.getMin(),parameter.getMax()));
}

void ofxBaseGroup::add(ofParameter<bool> & parameter){
	add(new ofxToggle(parameter.getName(),parameter));
}

void ofxBaseGroup::clear(){
	collection.clear();
	b.height = header + spacing; // weird to start out with something arbitrary like this
}

void ofxBaseGroup::mouseMoved(ofMouseEventArgs & args){
	ofMouseEventArgs a = args;
	a.x -= b.x;
	a.y -= b.y;
	for(int i = 0; i < (int)collection.size(); i++){
		collection[i]->mouseMoved(a);
	}
}

void ofxBaseGroup::mousePressed(ofMouseEventArgs & args){
	setValue(args.x, args.y, true);
	if( bGuiActive ){
		ofMouseEventArgs a = args;
		a.x -= b.x;
		a.y -= b.y;
		for(int i = 0; i < (int)collection.size(); i++){
			collection[i]->mousePressed(a);
		}
	}
}

void ofxBaseGroup::mouseDragged(ofMouseEventArgs & args){
	setValue(args.x, args.y, false);
	if( bGuiActive ){
		ofMouseEventArgs a = args;
		a.x -= b.x;
		a.y -= b.y;
		for(int i = 0; i < (int)collection.size(); i++){
			collection[i]->mouseDragged(a);
		}
	}
}

void ofxBaseGroup::mouseReleased(ofMouseEventArgs & args){
	bGuiActive = false;
	bGrabbed = false;
	for(int k = 0; k < (int)collection.size(); k++){
		ofMouseEventArgs a = args;
		a.x -= b.x;
		a.y -= b.y;
		collection[k]->mouseReleased(a);
	}
}

void ofxBaseGroup::draw(){
	ofPushStyle();
	ofPushMatrix();
    
	currentFrame = ofGetFrameNum();
    
	ofTranslate(b.x, b.y);
    
	ofFill();
	ofSetColor(headerBackgroundColor);
	ofRect(0, 0, b.width, header);
    
	ofSetColor(textColor);
	ofDrawBitmapString(name, textPadding, header / 2 + 4);
    
	for(int i = 0; i < (int)collection.size(); i++){
		collection[i]->draw();
	}
    
	ofPopMatrix();
	ofPopStyle();
}

vector<string> ofxBaseGroup::getControlNames(){
	vector<string> names;
	for(int i=0; i<(int)collection.size(); i++){
		names.push_back(collection[i]->getName());
	}
	return names;
}

ofxIntSlider ofxBaseGroup::getIntSlider(string name){
	return getControlType<ofxIntSlider>(name);
}

ofxFloatSlider ofxBaseGroup::getFloatSlider(string name){
	return getControlType<ofxFloatSlider>(name);
}

ofxToggle ofxBaseGroup::getToggle(string name){
	return getControlType<ofxToggle>(name);
}

ofxButton ofxBaseGroup::getButton(string name){
	return getControlType<ofxButton>(name);
}

ofxBaseGui * ofxBaseGroup::getControl(string name){
	for(int i=0; i<(int)collection.size(); i++){
		if(collection[i]->getName()==name){
			return collection[i];
		}
	}
	return NULL;
}

void ofxBaseGroup::setValue(float mx, float my, bool bCheck){
    
	if( ofGetFrameNum() - currentFrame > 1 ){
		bGrabbed = false;
		bGuiActive = false;
		return;
	}
	if( bCheck ){
		if( b.inside(mx, my) ){
			bGuiActive = true;
            
			if( my > b.y && my <= b.y + header ){
				bGrabbed = true;
				grabPt.set(mx-b.x, my-b.y);
			} else{
				bGrabbed = false;
			}
        }
	} else if( bGrabbed ){
		b.x = mx - grabPt.x;
		b.y = my - grabPt.y;
	}
}


int ofxBaseGroup::getNumControls(){
	return collection.size();
}

ofxBaseGui * ofxBaseGroup::getControl(int num){
	if(num<(int)collection.size())
		return collection[num];
	else
		return NULL;
}

ofAbstractParameter & ofxBaseGroup::getParameter(){
	return parameters;
}
