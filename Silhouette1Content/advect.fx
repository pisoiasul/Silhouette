texture velocity;
texture advected;
float2 gridSize;
float gridScale;
float timestep;
float dissipation;

sampler2D velocity_sampler : register(s1) = sampler_state
{
	Texture = <velocity>;
	Filter = POINT;
	AddressU = CLAMP;
	AddressV = CLAMP;
};

sampler2D advected_sampler : register(s2) = sampler_state
{
	Texture = <advected>;
	Filter = POINT;
	AddressU = CLAMP;
	AddressV = CLAMP;
};

float3 bilerp(sampler2D d, float2 p)
{
	float4 ij; // i0, j0, i1, j1
	ij.xy = floor(p - 0.5) + 0.5;
	ij.zw = ij.xy + 1.0;

	float4 uv = ij / gridSize.xyxy;
	float3 d11 = tex2D(d, uv.xy).xyz;
	float3 d21 = tex2D(d, uv.zy).xyz;
	float3 d12 = tex2D(d, uv.xw).xyz;
	float3 d22 = tex2D(d, uv.zw).xyz;

	float2 a = p - ij.xy;

	return lerp(lerp(d11, d21, a.x), lerp(d12, d22, a.x), a.y);
}

float4 PixelShaderFunction(float2 coords: TEXCOORD0) : COLOR0
{
	float2 uv = coords;
	float scale = 1.0 / gridScale;

	// trace point back in time
	float2 p = uv * gridSize.xy -timestep * tex2D(velocity_sampler, uv).xy;
	return float4(dissipation * bilerp(advected_sampler, p), 1.0);
}

technique Technique1
{
	pass Pass1
	{
		PixelShader = compile ps_2_0 PixelShaderFunction();
	}
}
