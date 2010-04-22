// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
function checkAll(name, value)  
{  
  chks = new Array();
  getElementsByClassName(name, document.body )
  for(var i=0;i <chks.length;i++)  
  {  
    chks[i].checked = value;  
  }  
}
  
function getElementsByClassName(strClassName,obj ) {
  if ( obj.className == strClassName ) {
    chks[chks.length] = obj;
  }
  for ( var i = 0; i < obj.childNodes.length; i++ )
    getElementsByClassName( strClassName, obj.childNodes[i] );
}
