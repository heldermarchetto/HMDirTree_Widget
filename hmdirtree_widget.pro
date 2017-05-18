;+
; NAME:
; HMDirTree_Widget
;
; PURPOSE:
; A compound widget object that provides a means for navigating directories
; using a tree view. This compound widget is largely based on Brad Gom's 
; compound widget "BGDirtree_widget"
; The main differences to BGDirtree_widget are:
; 1) HMDirTree_Widget does not issue one spawn command per folder. Issuing
;    so many spawn commands made the windows task bar go crazy.
; 2) HMDirTree_Widget does not handle files, only folders.
; 3) HMDirTree_Widget has no dependencies
; 4) HMDirTree_Widget always starts by searching for the available fixed 
;    drives (hard drives and network drives) and creating a list.  
;    To avoid hanging on slow network connections, the network drives are 
;    listed, but only explored when the user selects them.
; 5) HMDirTree_Widget allows only to select single directories, not multiple.
; 6) HMDirTree_Widget works only with IDL versions 8.0 or higher.
; 7) HMDirTree_Widget works only under Windows
;    
; CATEGORY:
; Widgets.
;
; CALLING SEQUENCE:
; Result = HMDirTree_Widget(Parent)
;
; INPUTS:
; Parent: The ID of the parent widget
;
; KEYWORD PARAMETERS:
; Event_func -- a user defined event handler function for the widget
; Event_pro -- a user defined event handler procedure for the widget
; Frame -- the widget frame thickness
; Initial_path -- set this keyword to a string path to select on startup
; Sensitive -- set this keyword to 0 to desensitize the widget on startup
; Uname -- a user name for the widget
; Uvalue -- a user value for the compount widget
; XSize -- the xsize in pixels for the widget
; YSize -- the ysize in pixels for the widget
;
; OUTPUTS:
; The widget returns event structures with the name HMDirTree_Event. The
; structure contains the following fields:
;
; ID: the widget ID
; TOP: the top widget ID
; HANDLER: the widget handler ID
; PATH: the selected file path
; NODE_ID:  the widget ID of the selected node
; OBJECT: a reference to the widget object.
;
;
; Using the get_value keyword in Widget_control returns a structure with the following fields:
; NAMES  a string array of pathnames for the selected object(s) if no objects are selected, then SELECTED=''
; NODE_ID:  an arrays of widget IDs for the selected objects
; OBJECT: a reference to the widget object.
;
; OBJECT PROCEDURE METHODS:
; Select,path -- select a folder. expand any parent folders.
; Set_Value,value -- sets the current value of the widget. Same result as calling widget_control
;                    with the set_value keyword
;
; OBJECT FUNCTION METHODS:
; GetID() -- returns the ID of the widget object
; Get_Value() -- returns the current value of the widget. Same result as calling widget_control
;                with the get_value keyword
;
; EXAMPLE:
;
; See the example procedure at the bottom of the file.
;
;
; MODIFICATION HISTORY:
;
; Written by Helder Marchetto, 18 May 2017
; Based on the original version:
;    * Oct 26  BGG Changed to an object widget
;    * Written by Brad Gom, 15 Oct 2005
;    * Oct 26  BGG Changed to an object widget
;    * Jun 11 2008 (BGG) - reverted to using findfile since file_search is too slow.
;    * Jul 30 2013 (BGG) - added wrappers for file_search as workaround for slow searches on network shares with many files.
;    * Jun 15 2015 (BGG) - fixed bug in VM/RT mode. Still very slow.
;    * Apr 19 2017 (BGG) - merged in edits from heldermarchetto to allow use in VM mode and Linux
;
;******************************************************************************************;
;                                                                                          ;
;  Copyright (c) 2017, by Helder Marchetto. All rights reserved.                           ;
;                                                                                          ;
;  Redistribution and use in source and binary forms, with or without                      ;
;  modification, are permitted provided that the following conditions are met:             ;
;                                                                                          ;
;      * Redistributions of source code must retain the above copyright                    ;
;        notice, this list of conditions and the following disclaimer.                     ;
;      * Redistributions in binary form must reproduce the above copyright                 ;
;        notice, this list of conditions and the following disclaimer in the               ;
;        documentation and/or other materials provided with the distribution.              ;
;      * The author's name may not be used to endorse or promote products derived          ;
;        from this software without specific prior written permission.                     ;
;                                                                                          ;
;  THIS SOFTWARE IS PROVIDED BY HELDER MARCHETTO ''AS IS'' AND ANY EXPRESS OR IMPLIED      ;
;  WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY    ;
;  AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL BRAD GOM BE      ;
;  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL       ;
;  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;    ;
;  LOSS OF USE, DATA, OR PROFITS; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ;
;  HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,   ;
;  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS   ;
;  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.                            ;
;******************************************************************************************;
;
; Disclaimer from original version:
;
;******************************************************************************************;
;                                                                                          ;
;  Copyright (c) 2015, by Brad Gom. All rights reserved.                                   ;
;                                                                                          ;
;  Redistribution and use in source and binary forms, with or without                      ;
;  modification, are permitted provided that the following conditions are met:             ;
;                                                                                          ;
;      * Redistributions of source code must retain the above copyright                    ;
;        notice, this list of conditions and the following disclaimer.                     ;
;      * Redistributions in binary form must reproduce the above copyright                 ;
;        notice, this list of conditions and the following disclaimer in the               ;
;        documentation and/or other materials provided with the distribution.              ;
;      * The author's name may not be used to endorse or promote products derived          ;
;        from this software without specific prior written permission.                     ;
;                                                                                          ;
;  THIS SOFTWARE IS PROVIDED BY BRAD GOM ''AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES,  ;
;  INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS    ;
;  FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL BRAD GOM BE LIABLE FOR ANY   ;
;  DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,  ;
;  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR  ;
;  PROFITS; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND    ;
;  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT              ;
;  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS           ;
;  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.                            ;
;******************************************************************************************;
;-

function HMDirTree::exploreTree, usePath
ps = path_sep()
if strmid(usePath,strlen(usePath)-1) ne ps then usePath += ps
queryStr = "Get-ChildItem '"+usePath+"' -Name -attributes D -Recurse -depth 1"
spawn, 'powershell '+queryStr,powerShellOutput, err
nRes = n_elements(powerShellOutput)
driveLetter = strupcase(strmid(usePath,0,1))
fInfo = {folderInfo, fullPath:'', shortName:'', driveLetter:'', hasSubs:0b, level:0b}
if (nRes eq 1l) && (powerShellOutput[0] eq '') then return, fInfo
subFolders = replicate(fInfo,nRes)
fInfoCounter=-1l
for k=0,nRes-1 do begin
    split = strsplit(powerShellOutput[k], ps, /extract, count=cnt)
    if (powerShellOutput[k]).contains('BeamtimeWells') then begin
       a =1
    endif
    fInfoCounter++
    subFolders[fInfoCounter].fullPath    = usePath+powerShellOutput[k]+ps
    subFolders[fInfoCounter].shortName   = split[-1]
    subFolders[fInfoCounter].driveLetter = driveLetter
    if cnt gt 1 then subFolders[fInfoCounter].level = 1b
endfor
subFolders = subFolders[0:fInfoCounter]
lOne = where(subFolders.level, cntOne, complement=lZero, ncomplement=cntZero)
for i=0,cntZero-1 do begin
   nf = where((subFolders[lOne].fullPath).contains(subFolders[lZero[i]].fullPath), hasSubs)
   subFolders[lZero[i]].hasSubs = hasSubs gt 0
endfor
return, subFolders
end

pro HMDirTree::refreshLeaf, id
compile_opt hidden
widget_control,/hourglass
widget_control,self.tree_id,update=0
if not widget_info(id,/valid) then return
widget_control,id,get_uvalue=uval
if self.debug then print, 'id='+string(id,format='(i04)')+'; path='+string(uval.path,format='(a16)')
if uval.path eq '' then stop

treeInfo = self->exploreTree(uval.path)
nNodes = n_elements(treeInfo)
if (nNodes eq 1l) && (treeInfo[0].fullPath eq '') then return

;Remove any nodes that don't exist anymore
ids=widget_info(id,/child)
destroy = list()
exist = list()
if ids ne 0 then begin
   widget_control,ids,get_uval=child_uval
   void = where(treeInfo.fullPath eq child_uval.path, cnt)
   if cnt eq 0 then destroy->add, ids else exist->add, {id:ids, path:child_uval.path}
   sibling=widget_info(ids,/sibling)
   while sibling ne 0 do begin
     widget_control,sibling,get_uval=sibling_uval
     void = where(treeInfo.fullPath eq sibling_uval.path, cnt)
     if cnt eq 0 then destroy->add, ids else exist->add, {id:sibling, path:sibling_uval.path}
     sibling=widget_info(sibling,/sibling)
   endwhile
endif
foreach dst, destroy do widget_control,dst,/destroy
destroy = 0b
if n_elements(exist) gt 0 then begin
   exist      = exist->toArray()
   exist_id   = exist.id
   exist_path = exist.path
endif else begin
   exist_path = ['#']
endelse

baseName = strlen(uval.path)
ps = path_sep()

;make all relevant base leaves
lOne = where(treeInfo.level, cntOne, complement=lZero, ncomplement=cntZero)
for i=0,cntZero-1 do begin
    node = treeInfo[lZero[i]]
    split = strsplit(strmid(node.fullPath,baseName), ps, /extract, count=cnt)
    pos = where(exist_path.contains(node.fullPath),exists)
    if exists eq 0l then leaf = widget_tree(id, value=node.shortName, /folder, uvalue={Method:"MainEvents", Object:self, path:node.fullPath, type:'folder'}) else leaf = exist_id[pos[0]]
    if node.hasSubs then begin
       nf = where((treeInfo[lOne].fullPath).contains(node.fullPath), hasSubs)
       for k=0, hasSubs-1 do begin
           void = where(exist_path.contains(treeInfo[lOne[nf[k]]].fullPath),exists)
           if self->find(treeInfo[lOne[nf[k]]].fullPath) le 0 then subLeaf = widget_tree(leaf, value=treeInfo[lOne[nf[k]]].shortName, /folder, uvalue={Method:"MainEvents", Object:self, path:treeInfo[lOne[nf[k]]].fullPath, type:'folder'})
       endfor
    endif
endfor
widget_control,self.tree_id,/update
end

pro HMDirTree::cleanup
compile_opt hidden
ptr_free,self.uvalue,self.drives,self.diskIcon,self.networkDiskIcon
end

function HMDirTree_Event_Handler, event
; The main event handler for the compound widget. It reacts
; to "messages" in the UValue of the widget.
; The message indicates which object method to call. A message
; consists of an object method and the self object reference.
compile_opt hidden
Widget_Control, event.ID, Get_UValue=theMessage
result = Call_Method(theMessage.method, theMessage.object, event)
RETURN, result
END

function HMDirTree::find,path ;returns ids of branches matching the path(s)
compile_opt hidden
if path[0] eq '' then return,0

;start at the root, then look for each folder in turn. If the folder doesn't exist yet,
;then fill it.
this_node=0L

;first, select the first drive in the tree
folderID=widget_info(self.tree_id,/child)
ids=[0L]  ;a list of ids for the matching items
if folderID eq 0 then return,0

for i=0,n_elements(path)-1 do begin
  ;start at the root, then look for each folder in turn. If the folder doesn't exist yet,
  ;then fill it.
  parts=strsplit(path[i],path_sep(),/extract,count=count)
  this_node=0L
  ;first, select the first drive in the tree
  folderID=widget_info(self.tree_id,/child)
  if folderID ne 0 then begin
    for j=0,count-1 do begin  ;step through the path parts, and see if any siblings match
      if j eq count-1 then select=1 else select=0   ;only select the final item in the path.

      while folderID ne 0 do begin  ;search the siblings and find a match until no more siblings (folderID=0)
        widget_control,folderID,get_value=name
        if strlowcase(name) eq strlowcase(parts[j]) then begin
          if select then ids=[ids,folderID] ;found a match, add it to the list
          break ; go to next part
        endif
        ;go to the next sibling folder
        folderID=widget_info(folderID,/sibling)
      endwhile
      ;either a match was found for the part, or we ran out of siblings
      if folderID eq 0 then break ;no match was found. go to next path
      ;go down a level
      folderID=widget_info(folderID,/child)
      ;check the next part
    endfor
  endif
endfor
if n_elements(ids) eq 1 then return,0 ;nothing found
return,ids[1:*]
end

function HMDirTree::GetID
compile_opt hidden
; This method returns the ID of the top-level base of the compound widget.
return, self.tlb
END

function HMDirTree::get_value
compile_opt hidden
sel = widget_info(self.tree_id,/tree_select)
nsel = n_elements(sel)
if sel[0] ne -1 then begin
  paths=strarr(nsel)
  for i=0,nsel-1 do begin
    widget_control,sel[i],get_value=name,get_uvalue=uval
    paths[i]=uval.path
  endfor
endif else paths=''
val={object:self, paths:paths, node_id:sel}  ;Create an event.
return,val
end

function HMDirTree_get_value,id
compile_opt hidden
;an interface to the get_value method for use by external programs calling widget_control.
stash=widget_info(id,/child)
widget_control,stash,get_uvalue=uval
obj=uval.object

return,obj->get_value()
end

pro HMDirTree_Kill_Notify,id
compile_opt hidden
widget_control,id,get_uvalue=uval
obj_destroy,uval.object
end

function HMDirTree::MainEvents, ev
compile_opt hidden
;The main event handler method for the compount widget
widget_control, ev.id, GET_UVALUE=uval
retpath=''
;Type 0 means select
;{WIDGET_TREE_SEL, ID:0L, TOP:0L, HANDLER:0L, TYPE:0, CLICKS:0L}
;Type 1 means expand or collapse (expand=0 on collapse)
;{WIDGET_TREE_EXPAND, ID:0L, TOP:0L, HANDLER:0L, TYPE:1, EXPAND:0L}

case uval.type of
    'root':begin  ;this should only generate events when we manually send an event to the root id.
             ;use this to avoid generating a string of events during the selection of the intial path.
             ev_name=TAG_NAMES( ev, /STRUCTURE_NAME )
             case ev_name of
               'HMDIRTREE_IGNORE' : self.ignore = 1
               'HMDIRTREE_ENABLE' : self.ignore =0
               else:
             endcase
             return,-1
           end
  'folder':begin
             ;search for all expanded folders and refresh the contents
             if self.debug then begin
               if ev.type eq 0 then type='select' else begin
                 if ev.expand eq 1 then type='expand' else type='collapse'
               endelse
               message,'Folder '+type+' event '+uval.path,/cont
             endif
             case ev.type of
                  0:begin ;a folder was selected
                      widget_control,ev.id,get_value=selected
                      widget_control,widget_info(ev.id,/sibling),get_value=child
                      drives = (*self.drives).driveLetter+':'+path_sep()
                      pos = where(drives eq uval.path, cntFound)
                      if (cntFound eq 1) && (widget_info((*self.drives)[pos[0]].id, /child) eq 0) then self->refreshLeaf, (*self.drives)[pos[0]].id 
                      retpath=uval.path
                    end
                  1:begin ;a folder was expanded or collapsed
                      if ev.expand eq 1 then begin  ;check the children folders and fill if necessary
                        widget_control,/hourglass
                        widget_control,self.tree_id,update=0,map=0
                        self->refreshLeaf, ev.id
                        widget_control,self.tree_id,update=1,map=1
                      endif else begin
                      endelse
                      return,-1 ;don't return an event for expand or collapse
                    end
                  else:
             endcase
           end
      else:print, 'unkown command'
endcase
sel = widget_info(self.tree_id,/tree_select)
nsel = n_elements(sel)
ret = {HMDIRTREE_EVENT, ID:self.tlb, TOP:ev.top, HANDLER:ev.top, path:retpath, node_id:ev.id, object:self}
if self.ignore then ret=-1  ;don't send an event during the initial phase
RETURN, ret
end

function HMDirTree::getGraphics, graphicsName
case graphicsName of
   'drive':begin
             b0 = [[255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255],$
                   [255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255],$
                   [255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255],$
                   [ 87, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63],$
                   [ 31,  0,  0,  0,  6, 43, 79,109,120, 39,  0,  0,  0,  0,  0,  0],$
                   [ 31, 37, 91,151,200,206,195,123, 83,147, 87,  9,  0,  0,  0,  0],$
                   [159,204,224,232,229,217,200,158,149,189,152,128, 42,  0,  0,  0],$
                   [202,208,221,228,206,193,183,179,194,212,213,178,150, 93,  8,  0],$
                   [201,207,207,209,216,214,215,215,203,191,185,200,206,172, 87,  0],$
                   [208,205,217,231,240,245,239,232,224,217,210,192,197,214,111,  0],$
                   [208,202,202,201,204,218,233,211,201,223,208,190,173,157,118,  0],$
                   [249,248,248,248,248,247,247,248,246,245,244,243,242,241,238,223],$
                   [255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255],$
                   [255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255],$
                   [255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255],$
                   [255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255]]
             b1 = [[255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255],$
                   [255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255],$
                   [255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255],$
                   [ 87, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63],$
                   [ 31,  0,  0,  0,  6, 43, 79,114,120, 39,  0,  0,  0,  0,  0,  0],$
                   [ 31, 37, 91,152,200,206,195,144, 84,147, 87,  9,  0,  0,  0,  0],$
                   [159,204,224,232,229,216,200,168,149,189,152,128, 42,  0,  0,  0],$
                   [202,208,221,228,206,193,183,179,194,212,213,178,150, 93,  8,  0],$
                   [201,207,206,208,215,215,217,217,205,192,186,201,206,172, 87,  0],$
                   [208,204,216,230,240,245,239,232,224,216,210,192,197,214,111,  0],$
                   [208,202,202,202,204,218,233,210,201,222,207,190,173,158,118,  0],$
                   [249,248,248,248,248,247,247,248,246,245,244,243,242,241,238,223],$
                   [255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255],$
                   [255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255],$
                   [255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255],$
                   [255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255]]
             b2 = [[255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255],$
                   [255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255],$
                   [255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255],$
                   [ 87, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63],$
                   [ 31,  0,  0,  0,  6, 43, 79,107,120, 39,  0,  0,  0,  0,  0,  0],$
                   [ 31, 37, 91,155,206,213,201,114, 84,147, 87,  9,  0,  0,  0,  0],$
                   [160,209,232,242,239,225,206,157,150,189,152,128, 42,  0,  0,  0],$
                   [203,213,229,236,213,198,184,179,194,212,213,178,150, 93,  8,  0],$
                   [201,207,206,206,214,216,219,219,207,194,187,201,206,172, 87,  0],$
                   [208,204,215,229,240,245,239,232,224,217,210,192,197,214,111,  0],$
                   [208,202,202,201,204,217,232,209,200,222,207,189,173,157,102,  0],$
                   [249,248,248,248,248,247,247,248,246,245,244,243,242,241,236,223],$
                   [255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255],$
                   [255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255],$
                   [255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255],$
                   [255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255]]
             b3 = [[  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0],$
                   [  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0],$
                   [  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0],$
                   [  0,  0,  0,  0,  0,  0,  1,  7, 12,  3,  0,  0,  0,  0,  0,  0],$
                   [  0,  0,  1,  9, 35, 93,148,194,219,126, 20,  0,  0,  0,  0,  0],$
                   [  6, 75,151,212,251,255,255,255,255,254,198, 60,  4,  0,  0,  0],$
                   [152,255,255,255,255,255,255,255,255,255,255,242,129, 19,  0,  0],$
                   [205,255,255,255,255,255,255,255,255,255,255,255,255,199, 52,  1],$
                   [160,254,255,255,255,255,255,255,255,255,255,255,255,255,152,  8],$
                   [  0, 39,126,213,255,255,255,255,255,255,255,255,255,255,136,  0],$
                   [  0,  0,  0,  0, 44,131,217,255,255,240,206,168,126, 76, 11,  0],$
                   [  0,  0,  0,  0,  0,  0,  0, 22, 12,  0,  0,  0,  0,  0,  0,  0],$
                   [  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0],$
                   [  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0],$
                   [  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0],$
                   [  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0]]
            sb0 = size(b0,/dimensions)
            button = make_array(4, sb0[0],sb0[1], /byte)
            button[0,*,*] = b0
            button[1,*,*] = b1
            button[2,*,*] = b2
            button[3,*,*] = b3
            return, transpose(button,[1,2,0])
          end
 'networkdrive':begin
                  b0 = [[  7,  6,  5,  4,  4,  6, 13,  4,  3,  2, 16, 49, 86, 39,  0,  0],$
                        [  7,  1,  2,  6,  2, 18, 26, 36, 51,145,198,204,196, 96,  3,  0],$
                        [  5,  6, 35, 32, 22,  9,  2, 18, 42,148,157,115, 73, 19,  1,  0],$
                        [ 86,179,222, 87, 36, 45, 51, 31, 12, 36, 27,  0,  0,  0,  0,  0],$
                        [ 91,138, 90, 35,  8,  5,  4, 50, 81,119,155,106, 16,  0,  0,  0],$
                        [  7,  3,  5, 16, 65,124,181,204,193, 89,128,136, 57,  0,  0,  0],$
                        [  4,  5, 14,181,216,230,230,218,200,146,185,177,144, 82,  9,  0],$
                        [  2,  4, 26,197,206,204,204,197,185,191,192,209,206,168,128, 25],$
                        [  4,  7,  8,110,195,240,226,224,226,223,207,193,183,201,199, 97],$
                        [  2,  9, 11,  6,  7, 56,140,219,245,236,229,223,212,188,153, 53],$
                        [  5,  4,  7,  4,  8,  8,  7,  5, 58, 75, 77, 65, 26,  6,  5,  0],$
                        [ 10,  4,  1,  5,  2,  2,  6,  7,  3,  8,  8,  9,  7,  7,  4,  0],$
                        [  0,  0,  0,  0,  2,  0,  0,  0,  0,  0,  0,  1,  2,  0,  0,  0],$
                        [  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0],$
                        [  2,  4,  6,  2,  0,  3,  2,  0,  6,  1,  3,  1,  3,  0,  3,  0],$
                        [ 10,  4,  9,  7,  3,  4,  4,  7, 14,  2,  5,  6,  2,  8,  0,  0]]
                  b1 = [[  7,  6,  5,  4,  4,  6, 13,  4,  3,  2, 18, 56, 98, 43,  0,  0],$
                        [  7,  1,  2,  6,  3, 30, 57, 83,123,167,206,209,203,105,  3,  0],$
                        [  5,  7, 40, 76,113,125,139,162,168,180,165,123, 79, 22,  1,  0],$
                        [ 97,191,229,206,225,239,239,224,152, 81, 29,  0,  0,  0,  0,  0],$
                        [ 96,145, 96, 57, 61, 15, 13,120,171,151,159,112, 17,  0,  0,  0],$
                        [  7,  3,  5, 16, 65,124,181,204,193,107,128,136, 60,  0,  0,  0],$
                        [  4,  5, 14,181,216,229,230,218,200,153,185,177,144, 82,  9,  0],$
                        [  2,  4, 26,197,206,204,203,196,185,191,192,209,206,168,128, 25],$
                        [  4,  7,  8,110,194,238,226,225,227,225,209,194,183,201,199, 97],$
                        [  2,  9, 11,  6,  7, 56,140,219,244,236,229,223,212,188,153, 53],$
                        [  5,  4,  7,  4,  8,  8,  7,  5, 58, 75, 77, 65, 26,  6,  5,  0],$
                        [ 10,  4,  1,  5,  2,  2,  6,  7,  3,  8,  8,  9,  7,  7,  4,  0],$
                        [  0,  0,  0,  0,  2,  0,  0,  0,  0,  0,  0,  1,  2,  0,  0,  0],$
                        [  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0],$
                        [  2,  4,  6,  2,  0,  3,  2,  0,  6,  1,  3,  1,  3,  0,  3,  0],$
                        [ 10,  4,  9,  7,  3,  4,  4,  7, 14,  2,  5,  6,  2,  8,  0,  0]]
                  b2 = [[  7,  6,  5,  4,  4,  6, 13,  4,  3,  2, 18, 57,101, 44,  0,  0],$
                        [  7,  1,  2,  6,  2, 23, 40, 56, 82,159,207,210,204,107,  3,  0],$
                        [  5,  7, 41, 52, 61, 58, 60, 79, 96,166,168,125, 80, 22,  1,  0],$
                        [100,194,231,139,117,128,131,113, 72, 56, 29,  0,  0,  0,  0,  0],$
                        [ 97,147, 97, 47, 30,  9,  8, 80,120,131,160,114, 17,  0,  0,  0],$
                        [  7,  3,  5, 16, 65,127,186,210,200, 80,129,136, 60,  0,  0,  0],$
                        [  4,  5, 14,182,222,239,240,227,207,145,185,177,144, 82,  9,  0],$
                        [  2,  4, 26,199,211,210,208,198,184,190,192,209,206,168,128, 25],$
                        [  4,  7,  8,109,193,237,225,226,229,227,211,196,184,201,199, 97],$
                        [  2,  9, 11,  6,  7, 56,140,219,244,235,228,222,211,188,153, 53],$
                        [  5,  4,  7,  4,  8,  8,  7,  5, 58, 75, 76, 65, 26,  6,  5,  0],$
                        [ 10,  4,  1,  5,  2,  2,  6,  7,  3,  8,  8,  9,  7,  7,  4,  0],$
                        [  0,  0,  0,  0,  2,  0,  0,  0,  0,  0,  0,  1,  2,  0,  0,  0],$
                        [  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0],$
                        [  2,  4,  6,  2,  0,  3,  2,  0,  6,  1,  3,  1,  3,  0,  3,  0],$
                        [ 10,  4,  9,  7,  3,  4,  4,  7, 14,  2,  5,  6,  2,  8,  0,  0]]
                  b3 = [[  0,  0,  0,  0,  0,  0,  0,  0,  4,  4, 23, 67,103, 32,  0,  0],$
                        [  0,  0,  0,  1, 11, 54,114,173,224,150,122,101,102, 64,  0,  0],$
                        [  1, 16, 56,154,238,255,255,255,255,193,120, 97, 62, 14,  0,  0],$
                        [ 80,130,114,206,255,251,243,255,255,192, 60, 22, 17,  9,  1,  0],$
                        [ 50, 88, 65, 54, 71, 28, 29,147,251,231,215,135, 36, 18,  8,  0],$
                        [  0,  0,  0, 18, 99,170,232,255,255,255,255,237,106, 16,  7,  0],$
                        [  0,  0,  1,231,255,255,255,255,255,255,255,255,254,160, 16,  0],$
                        [  0,  0, 14,255,255,255,255,255,255,255,255,255,255,254,228, 50],$
                        [  0,  0,  0,125,216,255,255,255,255,255,255,255,255,254,254,136],$
                        [  0,  0,  0,  0,  0, 49,135,221,255,255,255,255,254,234,185, 61],$
                        [  0,  0,  0,  0,  0,  0,  0,  0, 52,103, 86, 56, 21,  0,  0,  0],$
                        [  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0],$
                        [  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0],$
                        [  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0],$
                        [  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0],$
                        [  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0]]
                  sb0 = size(b0,/dimensions)
                  button = make_array(4, sb0[0],sb0[1], /byte)
                  button[0,*,*] = b0
                  button[1,*,*] = b1
                  button[2,*,*] = b2
                  button[3,*,*] = b3
                  return, transpose(button,[1,2,0])
          end
      else:
endcase
end

function HMDirTree::getDrives
spawn, 'powershell "Get-WmiObject Win32_LogicalDisk | select DeviceID, DriveType, VolumeName"',powerShellOutput, err
drives = {winDriveInfo, driveLetter:'', driveName:'', driveType:0l, id:-1l}
driveList = list()
nRes = n_elements(powerShellOutput)
for i = 0,nRes-1 do begin
    split = strsplit(powerShellOutput[i],':',/extract, count=cnt)
    if (cnt eq 2l) then begin
       driveInfo = strsplit(split[1],/extract, count=cntSplit)
       if cntSplit eq 1l then begin
          driveType = long(driveInfo[0])
          driveName = 'NoName'
       endif else begin
          driveType = long(driveInfo[0])
          driveName = strtrim(driveInfo[1],2)
          if driveName eq 'RECOVERY' then driveType = 0l
       endelse
       if (driveType eq 3l) || (driveType eq 4l) then driveList->add, {winDriveInfo, driveLetter:split[0], driveName:driveName, driveType:driveType, id:-1l}
    endif
endfor
if n_elements(driveList) gt 0 then return, driveList->toArray() $
                              else return, drives
end

pro HMDirTree::debugTree, id
widget_control, id, get_uval=uVal
print, string(id, format='(i4)')+' - '+strtrim(uVal.path,2)
ids=widget_info(id,/child)
treefoldercount=0
if ids ne 0 then begin
   widget_control,ids,get_uval=child_uval
   print, string(ids, format='(i4)')+' - '+strtrim(child_uval.path,2)
   sibling=widget_info(ids,/sibling)
   while sibling ne 0 do begin
     widget_control,sibling,get_uval=sibling_uval
     print, string(sibling, format='(i4)')+' - '+strtrim(sibling_uval.path,2)
     sibling=widget_info(sibling,/sibling)
   endwhile
endif
end

pro HMDirTree::RealizeNotify
compile_opt hidden
wTree=self.tree_id
self.drives          = ptr_new(self->getDrives())
self.diskIcon        = ptr_new(self->getGraphics('drive'))
self.networkDiskIcon = ptr_new(self->getGraphics('networkdrive'))

;add the roots for the drives
widget_control,wTree,update=0
for i=0,n_elements(*self.drives)-1 do begin
    wtRoot = widget_tree(wTree, value=(*self.drives)[i].driveLetter+':', /folder, bitmap=((*self.drives)[i].driveType eq 4l) ? *self.networkDiskIcon : *self.diskIcon, uvalue={Method:"MainEvents", Object:self, path:(*self.drives)[i].driveLetter+':'+path_sep(), type:'folder'})
    (*self.drives)[i].id = wtRoot
    if (*self.drives)[i].driveType eq 3l then self->refreshLeaf, wtRoot
endfor

self->select,self.initial_path
widget_control,wTree,/update

;now there will be a few events in the queue if an initial path was selected.
;send an event at the end of the queue to set self.ignore to 0, so that subsequent events get passed on.
widget_control,wTree,send_event={HMDirTree_enable, id:wTree, top:self.tlb, handler:self.tlb, Method:"MainEvents", Object:self}

if self.debug then begin
   ;check tree content
   foreach id, wtRoot do begin
      widget_control, id, get_uval=uVal
      print, string(id, format='(i4)')+' - '+strtrim(uVal.path,2)
      ids=widget_info(id,/child)
      treefoldercount=0
      if ids ne 0 then begin
         widget_control,ids,get_uval=child_uval
         print, string(ids, format='(i4)')+' - '+strtrim(child_uval.path,2)
         sibling=widget_info(ids,/sibling)
         while sibling ne 0 do begin
           widget_control,sibling,get_uval=sibling_uval
           print, string(sibling, format='(i4)')+' - '+strtrim(sibling_uval.path,2)
           sibling=widget_info(sibling,/sibling)
         endwhile
      endif
   endforeach
endif
end

pro HMDirTree_Realize_Notify,id
compile_opt hidden
widget_control,id,get_uval=uval
(uval.object)->RealizeNotify
end

pro HMDirTree::SetProperty, uvalue=uvalue
compile_opt hidden
if n_elements(uvalue) ne 0 then *self.uvalue = uvalue
end

pro HMDirTree::set_value,value
compile_opt hidden
message,'set_value method not implemented!',/cont
end

pro HMDirTree_set_value,id,value
compile_opt hidden
;an interface to the set_value method for use by external programs calling widget_control.
stash=widget_info(id,/child)
widget_control,stash,get_uvalue=uval
obj=uval.object
obj->set_value,value
end

pro HMDirTree::select, selectedPath  ;select a folder. expand any parent folders.
compile_opt hidden
if selectedPath eq '' then return
if not file_test(selectedPath) then return
;start at the root, then look for each folder in turn. If the folder doesn't exist yet,
;then fill it.
if file_test(selectedPath,/dir) then folder=1 else folder=0
ps = path_sep()
if strmid(selectedPath,strlen(selectedPath)-1) ne ps then selectedPath+=ps
parts=strsplit(selectedPath,ps,/extract,count=count)
parent = self.tree_ID
while widget_info(parent, /parent) ne 0 do parent = widget_info(parent, /Parent)
for i=0,count-1 do begin
    folderID = self->find(strjoin(parts[0:i],path_sep()))
    folderID = folderID[0]
    widget_control,folderID,/set_tree_expanded,set_tree_select=select
    if i ne count-1 then result = self->MainEvents({WIDGET_TREE_EXPAND,id:folderID,top:parent,handler:3,type:1,expand:1})
endfor
widget_control,folderID,/set_tree_select
return

this_node=0L

;first, select the first drive in the tree
folderID=widget_info(self.tree_id,/child)

if folderID eq 0 then return

widget_control,self.tree_id,update=0
for i=0,count-1 do begin  ;step through the path parts, and see if any siblings match
  expand=0
  if i eq count-1 then select=1 else select=0   ;only select the final item in the path.

  while folderID ne 0 do begin  ;search the siblings and find a match until no more siblings (folderID=0)
    widget_control,folderID,get_uvalue=name
    if i gt 0 then currentParts = strjoin(parts[0:i],ps)+ps else currentParts = parts[i]+ps
    if strlowcase(name.path) eq strlowcase(currentParts) then begin  ;found a match
      widget_control,folderID,/set_tree_expanded,set_tree_select=select
      parent = folderID
      while widget_info(parent, /parent) ne 0 do parent = widget_info(parent, /Parent)
      result = self->MainEvents({WIDGET_TREE_EXPAND,id:folderID,top:parent,handler:3,type:1,expand:1})
      break ; go to next part
    endif
    ;go to the next sibling folder
    folderID=widget_info(folderID,/sibling)
  endwhile
  folderID=widget_info(folderID,/child)
endfor
widget_control,self.tree_id,update=1
end

function HMDirTree::Init,$
                    parent,$
                    initial_path=initial_path,$
                    xsize=xsize,$
                    ysize=ysize,$
                    uvalue=uvalue,$
                    uname=uname,$
                    sensitive=sensitive,$
                    frame=frame,$
                    event_func=event_func,$
                    event_pro=event_pro,$
                    debug=debug,$
                    _extra=extra

compile_opt hidden
if n_elements(initial_path) eq 0 then initial_path=''
if n_elements(uvalue) eq 0 then uvalue=''
if n_elements(event_func) eq 0 then event_func=''
if n_elements(event_pro) eq 0 then event_pro=''
if keyword_set(debug) then debug=1 else debug=0

if float(!version.release) le 8.0 then begin
  message,'HMDirTree requires IDL8.0 or greater.',/info
  return,0
endif

if strupcase(!version.os_family) ne 'WINDOWS' then begin
  message,'HMDirTree runs only under Windows.',/info
  return,0
endif

base = widget_base(parent,/col, uvalue=uvalue, uname=uname, sensitive=sensitive, frame=frame, event_func=event_func, event_pro=event_pro, func_get_value='HMDirTree_get_value', pro_set_value='HMDirTree_set_value')
base_id=widget_base(base,/row,XPAD=2,YPAD=2,kill_notify='HMDirTree_Kill_Notify', notify_realize='HMDirTree_Realize_Notify',EVENT_FUNC='HMDirTree_event_handler', UValue={Method:"MainEvents", Object:self})
tree_id = widget_tree(base_id,xsize=xsize,ysize=ysize, uval={Method:"MainEvents", Object:self, path:'', type:'root'})

self.parent=parent
self.TLB=BASE
self.tree_ID=tree_ID
self.event_func=event_func
self.event_pro=event_pro
self.ignore=1
self.initial_path=initial_path
self.debug=debug
self.uvalue=ptr_new(uvalue)
return, 1
end

pro HMDirTree__Define
compile_opt hidden
;Define the HMDirTree widget object
object_class={HMDirTree,$
              parent:0L,$
              tlb:0L,$
              tree_ID:0L,$
              event_func: '',$
              event_pro: '',$
              ignore:0,$
              initial_path:'',$
              debug:0,$
              diskIcon:ptr_new(),$
              networkDiskIcon:ptr_new(),$
              drives:ptr_new(),$
              uvalue:ptr_new()}

; The HMDirTree Event Structure. Sent only if EVENT_PRO or EVENT_FUNC keywords
; have defined an event handler for the top-level base of the compound widget.
event = {HMDirTree_EVENT,$
         ID:0L,$
         TOP:0L,$
         HANDLER:0L, $
         path:'',$
         node_id:0L,$
         object:obj_new() }
end

function HMDirTree_Widget,parent,$
                          initial_path=initial_path,$
                          xsize=xsize,$
                          ysize=ysize,$
                          uvalue=uvalue,$
                          uname=uname,$
                          sensitive=sensitive,$
                          frame=frame,$
                          event_func=event_func,$
                          event_pro=event_pro,$
                          _extra=extra
compile_opt hidden
Return, obj_new("HMDirTree",$
                 parent,$
                 initial_path=initial_path,$
                 xsize=xsize,$
                 ysize=ysize,$
                 uvalue=uvalue,$
                 uname=uname,$
                 sensitive=sensitive,$
                 frame=frame,$
                 _extra=extra)
end

pro example_event,ev
widget_control,ev.id,get_uvalue=uval
widget_control,ev.top,get_uvalue=info
case uval of
  'folderSelect':begin
                   ;Option 1, use the event structure directly
                   help,ev,/str
                   ;Option 2, get the widget value
                   widget_control,ev.id,get_value=value
                   print,'files selected:',value.paths
                   ;Option 3, call object methods
                   obj=ev.object
                   ;     obj->refresh  ;call a method on the widget object.
                 end
          'done':widget_control,ev.top,/dest
endcase
end

pro example
initial_path='K:\Data\Bremen\IV_03'
tlb=widget_base(/col,title='HMDirTree_Widget Example')
obj=HMDirTree_Widget(tlb,initial_path=initial_path,uval='folderSelect',ysize=500,xsize=300);,/debug)
id=widget_button(tlb,value='Done',uvalue='done')
widget_control,tlb,/real
info={tlb:tlb, obj:obj}
widget_control,tlb,set_uvalue=info
xmanager,'example',tlb
end
