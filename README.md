# HMDirTree_Widget
A compound widget object that provides a means for navigating directories
using a tree view. This compound widget is largely based on Brad Gom's 
compound widget "BGDirtree_widget"
The main differences to BGDirtree_widget are:
1) HMDirTree_Widget does not issue one spawn command per folder. Issuing
   so many spawn commands made the windows task bar go crazy.
2) HMDirTree_Widget does not handle files, only folders.
3) HMDirTree_Widget has no dependencies
4) HMDirTree_Widget always starts by searching for the available fixed 
   drives (hard drives and network drives) and creating a list.  
   To avoid hanging on slow network connections, the network drives are 
   listed, but only explored when the user selects them.
5) HMDirTree_Widget allows only to select single directories, not multiple.
6) HMDirTree_Widget works only with IDL versions 8.0 or higher.
7) HMDirTree_Widget works only under Windows
