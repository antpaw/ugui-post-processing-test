using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.UI;

public class UIImageBloom : MonoBehaviour
{
    public enum DesamplingRate
    {
        None = 0,
        x1 = 1,
        x2 = 2,
        x4 = 4,
        x8 = 8,
    }
    public RawImage rawImage;
    public RenderTexture capturedTexture { get { return _rt; } }

    [Tooltip("Desampling rate of the generated RenderTexture.")]
    [SerializeField] DesamplingRate m_DesamplingRate = DesamplingRate.x1;

    [Tooltip("FilterMode for capturing.")]
    [SerializeField] FilterMode m_FilterMode = FilterMode.Bilinear;

    static int s_CopyId;
    static CommandBuffer s_CommandBuffer;

    RenderTargetIdentifier _rtId;
    RenderTexture _rt;

    void OnEnable()
    {
        int s_EffectId1 = Shader.PropertyToID("_UIEffectCapturedImage_EffectId1");

        int w, h;
        GetDesamplingSize(m_DesamplingRate, out w, out h);
        s_CommandBuffer = new CommandBuffer();
        s_CommandBuffer.GetTemporaryRT(s_CopyId, w, h, 0, m_FilterMode);
#if UNITY_EDITOR
        s_CommandBuffer.Blit(Resources.FindObjectsOfTypeAll<RenderTexture>().FirstOrDefault(x => x.name == "GameView RT"), s_CopyId);
#else
        s_CommandBuffer.Blit(BuiltinRenderTextureType.BindableTexture, s_CopyId);
#endif

        s_CommandBuffer.Blit(s_EffectId1, _rtId);
        s_CommandBuffer.ReleaseTemporaryRT(s_EffectId1);

#if !UNITY_EDITOR
        // Execute command buffer.
        Graphics.ExecuteCommandBuffer(s_CommandBuffer);
#endif
        _Release(false);
        rawImage.texture = capturedTexture;
        _SetDirty();
    }

    void Update()
    {

    }

    // 1:1 COPY
    public void GetDesamplingSize(DesamplingRate rate, out int w, out int h)
    {
#if UNITY_EDITOR
        if (!Application.isPlaying)
        {
            var res = UnityEditor.UnityStats.screenRes.Split('x');
            w = int.Parse(res[0]);
            h = int.Parse(res[1]);
        }
        else
#endif
        {
            w = Screen.width;
            h = Screen.height;
        }

        if (rate == DesamplingRate.None)
            return;

        float aspect = (float) w / h;
        if (w < h)
        {
            h = Mathf.ClosestPowerOfTwo(h / (int) rate);
            w = Mathf.CeilToInt(h * aspect);
        }
        else
        {
            w = Mathf.ClosestPowerOfTwo(w / (int) rate);
            h = Mathf.CeilToInt(w / aspect);
        }
    }

    void _Release(bool releaseRT)
    {
        if (releaseRT)
        {
            rawImage.texture = null;
            _Release(ref _rt);
        }

        if (s_CommandBuffer != null)
        {
            s_CommandBuffer.Clear();

            if (releaseRT)
            {
                s_CommandBuffer.Release();
                s_CommandBuffer = null;
            }
        }
    }

    void _Release(ref RenderTexture obj)
    {
        if (obj)
        {
            obj.Release();
            RenderTexture.ReleaseTemporary(obj);
            obj = null;
        }
    }

    [System.Diagnostics.Conditional("UNITY_EDITOR")]
    void _SetDirty()
    {
#if UNITY_EDITOR
        if (!Application.isPlaying)
        {
            UnityEditor.EditorUtility.SetDirty(this);
        }
#endif
    }

}
