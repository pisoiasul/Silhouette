texture Velocity;
texture Density;
texture DepthTexture;
texture DepthTextureOld;
float2 DepthSize;
float4x4 MatrixTransform;
float3 Color;

sampler SourceV : register(s1) = sampler_state
{
	Texture = <Velocity>;
	Filter = POINT;
	AddressU = CLAMP;
	AddressV = CLAMP;
};

sampler SourceD : register(s2) = sampler_state
{
	Texture = <Density>;
	Filter = POINT;
	AddressU = CLAMP;
	AddressV = CLAMP;
};

sampler DepthT : register(s3) = sampler_state
{
	Texture = <DepthTexture>;
	Filter = POINT;
	AddressU = CLAMP;
	AddressV = CLAMP;
};

sampler DepthT2 : register(s4) = sampler_state
{
	Texture = <DepthTextureOld>;
	Filter = POINT;
	AddressU = CLAMP;
	AddressV = CLAMP;
};

struct PSOutput {
	float4 V : COLOR0;
	float4 D : COLOR1;
};

PSOutput PixelShaderFunction(float2 coords: TEXCOORD0) : COLOR0
{
	PSOutput output;
	float2 crd = float2(1-coords.x, coords.y);
	output.V = tex2D(SourceV, coords);
	output.D = tex2D(SourceD, coords);
	float depth = tex2D(DepthT, crd);
	float depthOld = tex2D(DepthT2, crd);
	float z = depth - depthOld + 0.5;
	//output.D = float4(z, z, z, 1);
	//return output;
	if (abs(z-0.5) < 0.1) {
		return output;
	}
	float2 uv = crd * DepthSize;
	int c = 0, c1 = 0, c2 = 0;
	float2 vel = float2(0, 0);
	for (int i = -10; i < 10; i++)
		for (int j = -10; j < 10; j++) {
			float2 cd = float2(uv.x + i, uv.y + j) / DepthSize;
			float d = tex2D(DepthT, cd) - tex2D(DepthT2, cd) + 0.5;
			if (abs(d - 0.5) < 0.1) {
				c1++;
				if (i >= -5 && i < 5 && j >= -5 && j < 5) {
					c2++;
				}
			} else
			if (d < 0.8) {
				vel += float2(i, j);
				c++;
			}
		}
	if (c1 > 300 || c2 > 50) {
		return output;
	}
	output.D = float4(Color, 1);
	if (z >= 0.8) {
		if (c > 0) {
			vel /= c;
			// vel = vel / float2(5, 5);
			output.V += float4(vel, 0, 0);
		}
	}
	return output;
}

void SpriteVertexShader(inout float4 color : COLOR0,
	inout float2 texCoord : TEXCOORD0,
	inout float4 position : SV_Position)
{
	position = mul(position, MatrixTransform);
}

technique Technique1
{
	pass Pass1
	{
		PixelShader = compile ps_3_0 PixelShaderFunction();
		VertexShader = compile vs_3_0 SpriteVertexShader();
	}
}
