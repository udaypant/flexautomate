package
{
	import mx.controls.Button;
	
	[SomeMetaData(field="uniqueId")]
	public class CustomBtn extends Button
	{
		public function CustomBtn()
		{
			super();
		}
		
		public var uniqueId:String;
	}
}