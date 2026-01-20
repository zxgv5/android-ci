package dev.aaa1115910.bv.tv.screens.main.home
import android.content.Intent
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.GridItemSpan
import androidx.compose.foundation.lazy.grid.LazyGridState
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.itemsIndexed
import androidx.compose.foundation.lazy.grid.rememberLazyGridState
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onPreviewKeyEvent
import androidx.compose.ui.input.key.type
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.dimensionResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.tv.material3.Text
import dev.aaa1115910.biliapi.entity.user.DynamicVideo
import dev.aaa1115910.bv.tv.component.LoadingTip
import dev.aaa1115910.bv.entity.carddata.VideoCardData
import dev.aaa1115910.bv.entity.proxy.ProxyArea
import dev.aaa1115910.bv.tv.R
import dev.aaa1115910.bv.tv.activities.user.FollowActivity
import dev.aaa1115910.bv.tv.activities.video.UpInfoActivity
import dev.aaa1115910.bv.tv.activities.video.VideoInfoActivity
import dev.aaa1115910.bv.tv.component.videocard.SmallVideoCard
import dev.aaa1115910.bv.tv.util.ProvideListBringIntoViewSpec
import dev.aaa1115910.bv.viewmodel.home.DynamicViewModel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.flow.snapshotFlow
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.filter
import org.koin.androidx.compose.koinViewModel

@Composable
fun DynamicsScreen(
    modifier: Modifier = Modifier,
    lazyGridState: LazyGridState = rememberLazyGridState(),
    dynamicViewModel: DynamicViewModel = koinViewModel()
) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()

    // 修复：snapshotFlow 明确泛型+完整导入，解决所有类型推断错误
    LaunchedEffect(lazyGridState) {
        snapshotFlow<Int?> {
            lazyGridState.layoutInfo.visibleItemsInfo.lastOrNull()?.index
        }
        .distinctUntilChanged()
        .filter { index ->
            index != null 
            && dynamicViewModel.dynamicVideoList.isNotEmpty() 
            && index >= dynamicViewModel.dynamicVideoList.size - 15
            && !dynamicViewModel.loading
        }
        .collect {
            scope.launch(Dispatchers.IO) {
                dynamicViewModel.loadMore()
            }
        }
    }

    val onClickVideo: (DynamicVideo) -> Unit = { dynamic ->
        VideoInfoActivity.actionStart(
            context = context,
            aid = dynamic.aid,
            proxyArea = ProxyArea.checkProxyArea(dynamic.title)
        )
    }

    val onLongClickVideo: (DynamicVideo) -> Unit = { dynamic ->
        UpInfoActivity.actionStart(
            context,
            mid = dynamic.authorId,
            name = dynamic.author,
            face = dynamic.authorFace
        )
    }

    if (dynamicViewModel.isLogin) {
        val padding = dimensionResource(R.dimen.grid_padding)
        val spacedBy = dimensionResource(R.dimen.grid_spacedBy)

        ProvideListBringIntoViewSpec {
            LazyVerticalGrid(
                modifier = modifier
                    .fillMaxSize()
                    .onFocusChanged {}
                    .onPreviewKeyEvent {
                        if (it.type == KeyEventType.KeyUp && it.key == Key.Menu) {
                            context.startActivity(Intent(context, FollowActivity::class.java))
                            return@onPreviewKeyEvent true
                        }
                        false
                    },
                columns = GridCells.Fixed(4),
                state = lazyGridState,
                contentPadding = PaddingValues(padding),
                verticalArrangement = Arrangement.spacedBy(spacedBy),
                horizontalArrangement = Arrangement.spacedBy(spacedBy)
            ) {
                itemsIndexed(dynamicViewModel.dynamicVideoList) { _, item ->
                    SmallVideoCard(
                        data = remember(item.aid) {
                            // 修复：Long/Int 类型匹配（item.play 是 Long，用 -1L）
                            VideoCardData(
                                avid = item.aid,
                                title = item.title,
                                cover = item.cover,
                                play = item.play.takeIf { it != -1L },
                                danmaku = item.danmaku.takeIf { it != -1L },
                                upName = item.author,
                                time = item.duration * 1000L,
                                pubTime = item.pubTime,
                                isChargingArc = item.isChargingArc,
                                badgeText = item.chargingArcBadge
                            )
                        },
                        onClick = { onClickVideo(item) },
                        onLongClick = { onLongClickVideo(item) },
                        onFocus = {}
                    )
                }

                if (dynamicViewModel.loading) {
                    item(span = { GridItemSpan(maxLineSpan) }) {
                        Box(
                            modifier = Modifier.fillMaxSize(),
                            contentAlignment = Alignment.Center
                        ) {
                            LoadingTip()
                        }
                    }
                }

                if (!dynamicViewModel.hasMore && !dynamicViewModel.loading) {
                    item(span = { GridItemSpan(maxLineSpan) }) {
                        Text(
                            modifier = Modifier.fillMaxWidth(),
                            text = "没有更多了捏",
                            color = Color.White,
                            fontSize = 14.sp,
                            textAlign = TextAlign.Center
                        )
                    }
                }
            }
        }
    } else {
        Box(
            modifier = Modifier.fillMaxSize(),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = "请先登录",
                color = Color.White,
                fontSize = 16.sp
            )
        }
    }
}
